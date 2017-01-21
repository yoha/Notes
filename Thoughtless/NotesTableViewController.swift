//
//  NotesTableViewController.swift
//  Notes
//
//  Created by Yohannes Wijaya on 8/4/16.
//  Copyright © 2016 Yohannes Wijaya. All rights reserved.
//


import UIKit

class NotesTableViewController: UITableViewController {
    
    // MARK: - Stored Properties
    
    var notes = [Notes]()
    
    let deleteOrNotDeleteAlertView: FCAlertView = {
        let alertView = FCAlertView(type: .warning)
        alertView.dismissOnOutsideTouch = true
        alertView.hideDoneButton = true
        return alertView
    }()
    
    var indexPath: IndexPath?
    
    // MARK: - IBAction Methods
    
    @IBAction func unwindToNotesTableViewController(sender: UIStoryboardSegue) {
        guard let validNotesViewController = sender.source as? NotesViewController, let validNote = validNotesViewController.note else { return }
        if self.presentedViewController is UINavigationController {
            let newIndexPath = IndexPath(row: 0, section: 0)
            self.notes.insert(validNote, at: 0)
            self.tableView.insertRows(at: [newIndexPath], with: .top)
        }
        else {
            guard let selectedIndexPath = self.tableView.indexPathForSelectedRow, self.notes[selectedIndexPath.row].entry != validNote.entry else { return }
            self.notes.remove(at: selectedIndexPath.row)
            self.notes.insert(validNote, at: 0)
            self.tableView.reloadData()
        }
        self.saveNotes()
    }
    
    // MARK: - Helper Methods
    
    func loadSampleNotes() {
        guard let firstNote = Notes(entry: "Hello Sunshine! Come & tap me first!\n👇👇👇\n\nYou can power up your note by writing your words like **this** or _this_, create an [url link](http://apple.com), or even make a todo list:\n\n* Watch WWDC videos.\n* Write `code`.\n* Fetch my girlfriend for a ride.\n* Refactor `code`.\n\nOr even create quote:\n\n> A block of quote.\n\nTap *Go!* to preview your enhanced note.\n\nTap *How?* to learn more.", dateOfCreation: CurrentDateAndTimeHelper.get()) else { return }
        guard let secondNote = Notes(entry: "Swipe me left or tap edit to delete.", dateOfCreation: CurrentDateAndTimeHelper.get()) else { return }
        guard let thirdNote = Notes(entry: "Tap edit to move me or delete me.", dateOfCreation: CurrentDateAndTimeHelper.get()) else { return }
        self.notes += [firstNote, secondNote, thirdNote]
    }
    
    func displayShareSheet(from indexPath: IndexPath) {
        let activityViewController = UIActivityViewController(activityItems: [self.notes[indexPath.row].entry], applicationActivities: nil)
        self.present(activityViewController, animated: true) {
            self.setEditing(false, animated: true)
        }
    }
    
    // MARK: - NSCoding Methods
    
    func saveNotes() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.notes, toFile: Notes.archiveURL.path)
        if !isSuccessfulSave { print("unable to save note...") }
    }
    
    func loadNotes() -> [Notes]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Notes.archiveURL.path) as? [Notes]
    }
    
    // MARK: - UIViewController Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let loadedNotes = self.loadNotes() {
            self.notes = loadedNotes
        }
        else {
            self.loadSampleNotes()
        }
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(hexString: "#72889E")!]
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        self.tableView.separatorColor = UIColor(red: 114/255, green: 136/255, blue: 158/255, alpha: 0.075)
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        self.deleteOrNotDeleteAlertView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.title = "\(self.notes.count) Notes"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let validSegueIdentifier = segue.identifier, let validSegueIdentifierCase = NotesTableViewControllerSegue(rawValue: validSegueIdentifier) else {
            assertionFailure("Could not map segue identifier: \(segue.identifier)")
            return
        }
        
        switch validSegueIdentifierCase {
        case .segueToNotesViewControllerFromCell:
            guard let validNotesViewController = segue.destination as? NotesViewController,
                let selectedNoteCell = sender as? NotesTableViewCell,
                let selectedIndexPath = self.tableView.indexPath(for: selectedNoteCell) else { return }
            let selectedNote = self.notes[selectedIndexPath.row]
            validNotesViewController.note = selectedNote
        case .segueToNotesViewControllerFromAddButton:
            print("adding new note")
        }
    }
    
    // MARK: - UITableViewDataSource Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotesTableViewCell", for: indexPath) as! NotesTableViewCell
        
        let note = self.notes[indexPath.row]
        
        cell.noteLabel.text = note.entry
        cell.noteModificationTimeStampLabel.text = note.dateModificationTimeStamp
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let noteTobeMoved = self.notes[sourceIndexPath.row]
        self.notes.remove(at: sourceIndexPath.row)
        self.notes.insert(noteTobeMoved, at: destinationIndexPath.row)
    }
    
    // MARK: - UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let shareButton: UITableViewRowAction = {
            let tableViewRowAction = UITableViewRowAction(style: .normal, title: "Share", handler: { (_, indexPath) in
                self.displayShareSheet(from: indexPath)
            })
            tableViewRowAction.backgroundColor = UIColor(hexString: "#488AC6")
            return tableViewRowAction
        }()
        
        let deleteButton: UITableViewRowAction = {
            let tableViewRowAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { (_, indexPath) in
                self.indexPath = indexPath
                self.deleteOrNotDeleteAlertView.showAlert(inView: self,
                                                          withTitle: "Delete For Sure?",
                                                          withSubtitle: "There is no way to recover it.",
                                                          withCustomImage: nil,
                                                          withDoneButtonTitle: nil,
                                                          andButtons: [Delete.no.operation, Delete.yes.operation])
            })
            return tableViewRowAction
        }()
        
        return [shareButton, deleteButton]
    }
}

// MARK: - FCAlertViewDelegate Protocol

extension NotesTableViewController: FCAlertViewDelegate {
    func alertView(_ alertView: FCAlertView, clickedButtonIndex index: Int, buttonTitle title: String) {
        guard let validIndexPath = self.indexPath else { return }
        if title == Delete.yes.operation {
            self.notes.remove(at: validIndexPath.row)
            self.saveNotes()
            tableView.deleteRows(at: [validIndexPath], with: .fade)
            self.navigationItem.title = "\(self.notes.count) Notes"
        }
        else if title == Delete.no.operation {
            self.setEditing(false, animated: true)
        }
    }
}

// MARK: - NotesTableViewController Extension

extension NotesTableViewController {
    enum NotesTableViewControllerSegue: String {
        case segueToNotesViewControllerFromCell
        case segueToNotesViewControllerFromAddButton
    }
    
    enum Delete {
        case yes, no
        
        var operation: String {
            switch self {
            case .yes: return "Delete"
            case .no: return "Don't Delete"
            }
        }
    }
}