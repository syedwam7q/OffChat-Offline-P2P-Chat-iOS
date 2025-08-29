import UIKit

protocol MessageSearchDelegate: AnyObject {
    func searchDidSelectMessage(_ message: ChatMessage, in thread: ChatThread)
}

final class MessageSearchViewController: UIViewController {
    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView()
    private let noResultsLabel = UILabel()
    
    private var allThreads: [ChatThread]
    private var filteredResults: [(thread: ChatThread, message: ChatMessage)] = []
    
    weak var delegate: MessageSearchDelegate?
    
    init(threads: [ChatThread]) {
        self.allThreads = threads
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupSearchController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.searchBar.becomeFirstResponder()
    }
    
    private func setupViews() {
        title = "Search Messages"
        navigationItem.largeTitleDisplayMode = .never
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        // Navigation bar buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Table view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageSearchCell.self, forCellReuseIdentifier: MessageSearchCell.reuseID)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemBackground
        } else {
            tableView.backgroundColor = .white
        }
        
        // No results label
        noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        noResultsLabel.text = "No messages found"
        noResultsLabel.font = .systemFont(ofSize: 18, weight: .medium)
        noResultsLabel.textAlignment = .center
        noResultsLabel.isHidden = true
        
        if #available(iOS 13.0, *) {
            noResultsLabel.textColor = .secondaryLabel
        } else {
            noResultsLabel.textColor = .gray
        }
        
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // No results label
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noResultsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            noResultsLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search messages..."
        
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.backgroundColor = UIColor.systemGray6
        }
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func performSearch(with query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            filteredResults = []
            updateUI()
            return
        }
        
        let lowercaseQuery = query.lowercased()
        filteredResults = []
        
        for thread in allThreads {
            for message in thread.messages {
                if message.text.lowercased().contains(lowercaseQuery) ||
                   message.sender.lowercased().contains(lowercaseQuery) {
                    filteredResults.append((thread: thread, message: message))
                }
            }
        }
        
        // Sort by most recent first
        filteredResults.sort { $0.message.timestamp > $1.message.timestamp }
        
        updateUI()
    }
    
    private func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let hasResults = !self.filteredResults.isEmpty
            let hasSearchText = !(self.searchController.searchBar.text?.isEmpty ?? true)
            
            self.tableView.isHidden = !hasResults
            self.noResultsLabel.isHidden = !hasSearchText || hasResults
            
            self.tableView.reloadData()
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension MessageSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageSearchCell.reuseID, for: indexPath) as! MessageSearchCell
        
        let result = filteredResults[indexPath.row]
        let searchQuery = searchController.searchBar.text ?? ""
        
        cell.configure(with: result.message, thread: result.thread, searchQuery: searchQuery)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MessageSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let result = filteredResults[indexPath.row]
        delegate?.searchDidSelectMessage(result.message, in: result.thread)
        
        dismiss(animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension MessageSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        performSearch(with: query)
    }
}

// MARK: - MessageSearchCell
final class MessageSearchCell: UITableViewCell {
    static let reuseID = "MessageSearchCell"
    
    private let senderLabel = UILabel()
    private let messageLabel = UILabel()
    private let threadLabel = UILabel()
    private let timeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupViews() {
        // Sender label
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        senderLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        if #available(iOS 13.0, *) {
            senderLabel.textColor = .label
        } else {
            senderLabel.textColor = .black
        }
        
        // Message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.numberOfLines = 3
        
        if #available(iOS 13.0, *) {
            messageLabel.textColor = .secondaryLabel
        } else {
            messageLabel.textColor = .darkGray
        }
        
        // Thread label
        threadLabel.translatesAutoresizingMaskIntoConstraints = false
        threadLabel.font = .systemFont(ofSize: 13, weight: .medium)
        threadLabel.textColor = .systemBlue
        
        // Time label
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        if #available(iOS 13.0, *) {
            timeLabel.textColor = .tertiaryLabel
        } else {
            timeLabel.textColor = .lightGray
        }
        
        contentView.addSubview(senderLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(threadLabel)
        contentView.addSubview(timeLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Sender label
            senderLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            senderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            senderLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            
            // Time label
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Message label
            messageLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Thread label
            threadLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 6),
            threadLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            threadLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            threadLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with message: ChatMessage, thread: ChatThread, searchQuery: String) {
        senderLabel.text = message.sender
        messageLabel.attributedText = highlightedText(message.text, searchQuery: searchQuery)
        threadLabel.text = "in \(thread.title)"
        timeLabel.text = formatTime(message.timestamp)
    }
    
    private func highlightedText(_ text: String, searchQuery: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        if !searchQuery.isEmpty {
            let range = NSString(string: text).range(of: searchQuery, options: .caseInsensitive)
            if range.location != NSNotFound {
                attributedString.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.3), range: range)
                attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: range)
            }
        }
        
        return attributedString
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        }
        
        return formatter.string(from: date)
    }
}