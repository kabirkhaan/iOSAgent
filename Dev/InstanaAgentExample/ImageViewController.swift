//
//  ImageViewViewController.swift
//  iOSAgentExample
//  Copyright © 2021 IBM Corp. All rights reserved.
//

import UIKit
import Combine
import InstanaAgent
import AFNetworking
import Alamofire

class ImageViewViewController: UIViewController {

    lazy var imageView = UIImageView()
    lazy var session = { URLSession(configuration: URLSessionConfiguration.default) }()
    private var publisher: AnyCancellable?
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(downloadImage)))

        timer = Timer.scheduledTimer(timeInterval: 35.0, target: self, selector: #selector(downloadImage), userInfo: nil, repeats: true)
        timer?.fire()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Instana.setView(name: "ImageView")
        Instana.setMeta(value: "iOS", key: "OS")
    }

    @objc func downloadImage() {
        let url = URL(string: "https://picsum.photos/900")!
        let function = [downloadWViaAFN, downloadViaCombine, downloadViaAlamofire].randomElement()!
        function(url)
        DispatchQueue.global().async {
            function(url)
        }
    }

    func downloadViaCombine(_ url: URL) {
        publisher = session.dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .map { UIImage(data: $0.data) }
            .replaceError(with: UIImage())
            .assign(to: \.image, on: self.imageView)
    }

    func downloadWViaAFN(_ url: URL) {
        let manager = AFURLSessionManager(sessionConfiguration: .default)
        manager.responseSerializer = AFHTTPResponseSerializer()
        let request = URLRequest(url: url)
        manager.dataTask(with: request, uploadProgress: nil, downloadProgress: nil) { response, data, error in
            DispatchQueue.main.async {
                guard let data = data as? Data else { return }
                self.imageView.image = UIImage(data: data)
            }
        }.resume()
    }

    func downloadViaAlamofire(_ url: URL) {
        let request = AF.request(url)
        request.response { result in
            DispatchQueue.main.async {
                guard let data = result.data else { return }
                self.imageView.image = UIImage(data: data)
            }
        }
    }
}
