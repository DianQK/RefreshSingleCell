//
//  ViewController.swift
//  RefreshSingleCell
//
//  Created by DianQK on 2018/6/5.
//  Copyright © 2018 DianQK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Flix
import SnapKit

class TextProvider: SingleUITableViewCellProvider {

    let firstElement = BehaviorRelay<String>(value: "0")

    let titleLabel = UILabel()

    let disposeBag = DisposeBag()

    override init() {
        super.init()
        titleLabel.numberOfLines = 0

        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(15)
            make.trailing.equalTo(contentView).offset(-15)
        }

        firstElement
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)

        firstElement.skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.tableView?.performBatchUpdates(nil, completion: nil)
            })
            .disposed(by: disposeBag)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath, value: SingleTableViewCellProvider<UITableViewCell>) -> CGFloat? {
        let attributedString = NSAttributedString(string: firstElement.value, attributes: [
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)
            ])
        let constraintSize = CGSize(width: tableView.bounds.width - 30, height: CGFloat.greatestFiniteMagnitude)
        return attributedString.boundingRect(with: constraintSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil).height + 25
    }

}

class ListProvider: TableViewProvider {

    typealias Cell = UITableViewCell
    typealias Value = String

    func createValues() -> Observable<[String]> {
        return Observable.just((1..<30).map(String.init))
    }

    func configureCell(_ tableView: UITableView, cell: UITableViewCell, indexPath: IndexPath, value: String) {
        cell.textLabel?.text = value
    }

}

class ViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let textProvider = TextProvider()

        tableView.rx.willDisplayCell.asObservable().filter { $0.indexPath.row == 0 }
            .take(1)
            .flatMapLatest { _ in Observable<Int>.interval(1, scheduler: MainScheduler.instance).skip(1).take(20) }
            .map { Array(repeating: "\($0)", count: $0 * 10).joined() }
            .bind(to: textProvider.firstElement)
            .disposed(by: disposeBag)

        tableView.flix.build([
            textProvider,
            ListProvider()
            ])

    }
}

