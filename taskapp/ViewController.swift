//
//  ViewController.swift
//  taskapp
//
//  Created by 新井美咲 on 2022/12/02.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // Realm内のタスクが格納される配列。
    // 日付の近い順でソート：昇順
    // データベースに追加や削除される度に自動で更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // データを表示していない部分に罫線を表示するコード
        tableView.fillerRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
    }
    
    // データの数（＝セルの数、taskArrayの要素数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // taskArrayから該当するデータを取り出してセルに設定
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        // DateFormatterクラスは日付を表すDateクラスを任意の形の文字列に変換する
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    // UITableViewDelegateプロトコルのメソッドで、セルをタップした時にタスク入力画面に遷移させる
    // Tells the delegate a row is selected.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // UITableViewDelegateプロトコルのメソッドで、セルが削除が可能なことを伝えるメソッド
    //Asks the delegate for the editing style of a row at a particular location in a table view.
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // UITableViewDataSourceプロトコルのメソッドで、Delete ボタンが押された時にローカル通知をキャンセルし、データベースからタスクを削除する
    // Asks the data source to commit the insertion or deletion of a specified row.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            // Realmクラスのdeleteメソッドに削除したいオブジェクト（Taskクラスのインスタンス）を与える
            // tryはSwiftのエラーハンドリングの仕組み
            // 今回はエラーが発生する可能性は極端に低いためtry!と記述して無視
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        let searchText = searchBar.text!
        let predicate = NSPredicate(format: "category == %@", searchText)
        let newArray = try! Realm().objects(Task.self).filter(predicate)
        taskArray = newArray
        tableView.reloadData()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            taskArray = try! Realm().objects(Task.self)
            tableView.reloadData()
        }
    }
        // segue で画面遷移する時に呼ばれる
        // segueのIDを指定して遷移させる
        override func prepare(for segue: UIStoryboardSegue, sender: Any?){
            let inputViewController:InputViewController = segue.destination as! InputViewController
            // セルをタップした時
            if segue.identifier == "cellSegue" {
                let indexPath = self.tableView.indexPathForSelectedRow
                inputViewController.task = taskArray[indexPath!.row]
            } else {
                // +ボタンをタップした時
                let task = Task()
                
                let allTasks = realm.objects(Task.self)
                // すでに存在しているタスクのidのうち最大のものを取得し、1を足すことで他のidと重ならない値を指定
                if allTasks.count != 0 {
                    task.id = allTasks.max(ofProperty: "id")! + 1
                }
                
                inputViewController.task = task
            }
        }
        // タスク作成/編集画面から戻ってきた時に TableView を更新させる
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            tableView.reloadData()
        }
    }
