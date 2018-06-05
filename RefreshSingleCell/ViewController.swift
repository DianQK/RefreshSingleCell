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
import RxDataSources

class TableViewCell: UITableViewCell {

    private(set) var reuseBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }

}

class ViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    typealias SectionModel = RxDataSources.SectionModel<(),  BehaviorRelay<String>>

    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel>(configureCell: { (dataSource, tableView, indexPath, value) -> UITableViewCell in
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        value.asObservable().bind(to: cell.textLabel!.rx.text).disposed(by: cell.reuseBag)
        return cell
    })

    let elements = (1..<30).map(String.init).map(BehaviorRelay<String>.init)

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rx.setDelegate(self).disposed(by: disposeBag)

        tableView.register(TableViewCell.self, forCellReuseIdentifier: "cell")

        Observable.just(elements)
            .map { [SectionModel(model: (), items: $0)] }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        tableView.rx.willDisplayCell.asObservable().filter { $0.indexPath.row == 0 }
            .take(1)
            .flatMapLatest { _ in Observable<Int>.interval(1, scheduler: MainScheduler.instance).take(10) }
            .map(String.init)
            .bind(to: elements[0])
            .disposed(by: disposeBag)

    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

}

