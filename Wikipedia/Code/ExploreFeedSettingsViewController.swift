import UIKit

private struct Section {
    let headerTitle: String
    let footerTitle: String
    let items: [Item]
}

private protocol Item {
    var title: String { get }
    var disclosureType: WMFSettingsMenuItemDisclosureType { get }
    var discloureText: String? { get }
    var type: ItemType { get }
    var iconName: String? { get }
    var iconColor: UIColor? { get }
    var iconBackgroundColor: UIColor? { get }
}

private protocol SwitchItem: Item {
    var controlTag: Int { get }
    var isOn: Bool { get }
}

extension SwitchItem {
    var disclosureType: WMFSettingsMenuItemDisclosureType { return .switch }
    var discloureText: String? { return nil }
    var iconName: String? { return nil }
    var iconColor: UIColor? { return nil }
    var iconBackgroundColor: UIColor? { return nil }
}

private struct FeedCard: Item {
    let title: String
    let disclosureType: WMFSettingsMenuItemDisclosureType
    let discloureText: String?
    let type: ItemType
    let iconName: String?
    let iconColor: UIColor?
    let iconBackgroundColor: UIColor?

    init(type: ItemType) {
        self.type = type
        switch type {
        case .inTheNews:
            title = "In the news"
            disclosureType = .viewController
            separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
            disclosureType = .viewControllerWithDisclosureText
            discloureText = disclosureTextString()
            iconName = "in-the-news-mini"
            iconColor = UIColor(red: 0.639, green: 0.663, blue: 0.690, alpha: 1.0)
            iconBackgroundColor = UIColor.wmf_lighterGray
        case .onThisDay:
            title = "On this day"
            disclosureType = .viewControllerWithDisclosureText
            discloureText = disclosureTextString()
            iconName = "on-this-day-mini"
            iconColor = UIColor(red: 0.243, green: 0.243, blue: 0.773, alpha: 1.0)
            iconBackgroundColor = UIColor(red: 0.922, green: 0.953, blue: 0.996, alpha: 1.0)
        default:
            assertionFailure() // TODO
            title = "In the news"
            disclosureType = .viewController
            iconName = "in-the-news-mini"
            iconColor = UIColor(red: 0.639, green: 0.663, blue: 0.690, alpha: 1.0)
            iconBackgroundColor = UIColor.wmf_lighterGray
        }
    }
}

private struct Language: SwitchItem {
    let title: String
    let type: ItemType
    let controlTag: Int
    let isOn: Bool
    let siteURL: URL

    init(_ languageLink: MWKLanguageLink, controlTag: Int) {
        type = ItemType.language(languageLink)
        title = languageLink.localizedName
        self.controlTag = controlTag
        isOn = languageLink.isInFeed
        siteURL = languageLink.siteURL()
    }
}

private enum ItemType {
    case inTheNews
    case onThisDay
    case continueReading
    case becauseYouRead
    case featuredArticle
    case topRead
    case pictureOfTheDay
    case places
    case randomizer
    case language(MWKLanguageLink)
}

@objc(WMFExploreFeedSettingsViewController)
class ExploreFeedSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @objc var dataStore: MWKDataStore?

    private var theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore feed"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: CommonStrings.backTitle, style: .plain, target: nil, action: nil)
        tableView.estimatedSectionFooterHeight = UITableViewAutomaticDimension
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.register(WMFTableHeaderFooterLabelView.wmf_classNib(), forHeaderFooterViewReuseIdentifier: WMFTableHeaderFooterLabelView.identifier())
        apply(theme: theme)
    }

    private lazy var languages: [Language] = { // maybe a set
        let preferredLanguages = MWKLanguageLinkController.sharedInstance().preferredLanguages
        let languages = preferredLanguages.enumerated().compactMap { (index, languageLink) in
            Language(languageLink, controlTag: index)
        }
        return languages
    }()

    private var sections: [Section] {
        let inTheNews = FeedCard(type: .inTheNews)
        let onThisDay = FeedCard(type: .onThisDay)
        let customization = Section(headerTitle: "Customize the Explore feed", footerTitle: "Hiding an card type will stop this card type from appearing in the Explore feed. Hiding all Explore feed cards will turn off the Explore tab. ", items: [inTheNews, onThisDay])

        let languages = Section(headerTitle: "Languages", footerTitle: "Hiding all Explore feed cards in all of your languages will turn off the Explore Tab.", items: self.languages)

        return [customization, languages]
    }

    private func getItem(at indexPath: IndexPath) -> Item {
        return sections[indexPath.section].items[indexPath.row]
    }

    private func getSection(at index: Int) -> Section {
        assert(sections.indices.contains(index), "Section at index \(index) doesn't exist")
        return sections[index]
    }
}

extension ExploreFeedSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = getSection(at: section)
        return section.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier(), for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        let item = getItem(at: indexPath)
        if let switchItem = item as? SwitchItem {
            configureSwitch(cell, switchItem: switchItem)
        } else {
            cell.configure(item.disclosureType, disclosureText: item.discloureText, title: item.title, subtitle: "EN, PL", iconName: item.iconName, iconColor: item.iconColor, iconBackgroundColor: item.iconBackgroundColor, theme: theme)
        }
        return cell
    }

    private func configureSwitch(_ cell: WMFSettingsTableViewCell, switchItem: SwitchItem) {
        cell.configure(.switch, title: switchItem.title, iconName: switchItem.iconName, isSwitchOn: switchItem.isOn, iconColor: switchItem.iconColor, iconBackgroundColor: switchItem.iconBackgroundColor, controlTag: switchItem.controlTag, theme: theme)
        cell.delegate = self
    }
}

// MARK: - UITableViewDelegate

extension ExploreFeedSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = getSection(at: section)
        return section.headerTitle
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: WMFTableHeaderFooterLabelView.identifier()) as? WMFTableHeaderFooterLabelView else {
            return nil
        }
        let section = getSection(at: section)
        footer.setShortTextAsProse(section.footerTitle)
        footer.type = .footer
        if let footer = footer as Themeable? {
            footer.apply(theme: theme)
        }
        return footer
    }
}

// MARK: - Themeable

extension ExploreFeedSettingsViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension ExploreFeedSettingsViewController: WMFSettingsTableViewCellDelegate {
    func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        guard let language = languages.first(where: { $0.controlTag == sender.tag }) else {
            assertionFailure("No language for a given control tag")
            return
        }
        let feedContentController = dataStore?.feedContentController
        feedContentController?.updateExploreFeedPreferences(forSiteURLs: [language.siteURL], shouldHideAllContentSources: !sender.isOn) {
            feedContentController?.updateFeedSourcesUserInitiated(true)
        }
    }
}