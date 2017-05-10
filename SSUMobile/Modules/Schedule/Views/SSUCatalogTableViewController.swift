//
//  SSUCatalogTableViewController.swift
//  SSUMobile
//
//  Created by Jonathon Thompson on 5/8/17.
//  Copyright © 2017 Sonoma State University Department of Computer Science. All rights reserved.
//

import Foundation
extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}

class SSUCatalogTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate  {
    
    var context: NSManagedObjectContext = SSUScheduleModule.instance.context!
    var backgroundImageView: UIImageView?
    private var catalog: [SSUCourse]?
    private var filterCatalog: [SSUCourse]?
    var searchController: UISearchController!
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        title = "SSU Catalog"
        filterCatalog = []
        
        if let image = UIImage(named: "table_background_image") {
            backgroundImageView = UIImageView(image: image)
            self.tableView.backgroundView = backgroundImageView
        }
        
        
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
        
        
        
        UIBarButtonItem.appearance().tintColor = .white


        refresh()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.flashScrollIndicators()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
//        self.tableView.setEditing(editing, animated: animated)
//    }
    
    private func refresh() {
        SSUScheduleModule.instance.updateData({
            self.loadSchedule()
        })
    }
    
    private func loadSchedule() {
        let fetchRequest: NSFetchRequest<SSUCourse> = SSUCourse.fetchRequest()
        
        do {
            catalog = try context.fetch(fetchRequest)
        } catch {
            SSULogging.logError("Error fetching schedule: \(error)")
            catalog = []
        }
        
        
        
        DispatchQueue.main.async {
            self.reloadScheduleTableView()
        }
    }
    
    private func reloadScheduleTableView() {
        tableView.reloadData()
    }
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = filterCatalog?.count else {
            return 0
        }
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseViewCell", for: indexPath)
        
        if let theCell = cell as? SSUCourseViewCell{
            theCell.transferClassInfo(course: (filterCatalog![indexPath.row]))
            // theCell.layoutMargins = UIEdgeInsets.zero
            // theCell.separatorInset = UIEdgeInsets.zero
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        // header.textLabel?.font = UIFont(name: "Futura", size: 11)
        // header.backgroundColor = UIColorFromHex(rgbValue: 0xf7f7f7)
        header.contentView.backgroundColor = UIColorFromHex(rgbValue: 0x215EA8)
        header.textLabel?.textColor = UIColorFromHex(rgbValue: 0xFFFFFF)
        header.textLabel?.textAlignment = .center
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "courseToDetails"{
            let cell = sender as! SSUCourseViewCell
            if let indexPath = tableView.indexPath(for: cell), let aClass = catalog?[(indexPath.row)] {
                
                print("CSTVC:\tprepare:\tsection = \((indexPath.section))\trow = \((indexPath.row))")
                print("printing oldClass:")
                
                let detailsVC = segue.destination as! SSUCourseDetailViewController
                detailsVC.passClassData(aClass)
            }
            
        }
    }
    
    // MARK: - UISearchResultsUpdater
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text
        self.searchFor(text: searchString)
        self.tableView.reloadData()
    }
    
    func searchFor(text:String?){
//        let searchTerms = text?.removingWhitespaces()
        if (catalog == nil) {
            return
        }
        if (text == ""){
            filterCatalog = catalog
            return
        }
        
        var tempset:Set<SSUCourse>
        var setArray:Array<Set<SSUCourse>> = []
        for searchTerms in (text?.lowercased().components(separatedBy: .whitespaces))!{
            if (searchTerms == ""){
                break
            }
            let innerSet = Set(catalog!.filter({
                (item:SSUCourse) in
                return item.catalog?.lowercased().range(of:searchTerms) != nil ||
                        item.department?.lowercased().range(of:searchTerms) != nil ||
                        item.last_name?.lowercased().range(of:searchTerms) != nil ||
                        item.first_name?.lowercased().range(of:searchTerms) != nil
            }))
            
//            innerSet = innerSet.union(Set(catalog!.filter({
//                (item:SSUCourse) in
//                return item.department?.lowercased().range(of:searchTerms) != nil
//            })))
            
//            innerSet = innerSet.union(Set(catalog!.filter({
//                (item:SSUCourse) in
//                return item.first_name?.lowercased().range(of:searchTerms) != nil
//            })))
//            
//            innerSet = innerSet.union(Set(catalog!.filter({
//                (item:SSUCourse) in
//                return item.last_name?.lowercased().range(of:searchTerms) != nil
//            })))
            
            setArray.append(innerSet)
        }
        
        if(setArray.isEmpty) {
            return
        }
        tempset = setArray.removeFirst()
        for s in setArray {
            tempset = tempset.intersection(s)
        }
        
        filterCatalog = Array(tempset)

        
//        if(filterCatalog?.isEmpty)!{
//            filterCatalog = catalog
//        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        filterCatalog = catalog
        
    }
    
}
