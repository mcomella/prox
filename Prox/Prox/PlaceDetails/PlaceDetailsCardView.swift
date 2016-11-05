/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol PlaceDetailsCardDelegate: class {
    func placeDetailsCardView(cardView: PlaceDetailsCardView, heightDidChange newHeight: CGFloat)
}

class PlaceDetailsCardView: UIView {

    weak var delegate: PlaceDetailsCardDelegate?

    let margin: CGFloat = 24
    let CardMarginBottom: CGFloat = 20 // TODO: name

    lazy var containingStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews:[self.labelContainer,
                                                 self.iconInfoViewContainer,
                                                 self.reviewViewContainer,
                                                 self.wikiDescriptionView,
                                                 self.yelpDescriptionView
            ])
        view.axis = .vertical
        view.spacing = self.margin

        self.setContainingStackViewLayoutMargins(forView: view, isDescriptionPresent: true)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()
    private func setContainingStackViewLayoutMargins(forView defaultView: UIStackView? = nil,
                                                     isDescriptionPresent: Bool) {
        // HACK: we want to call this method when containingStackView is initializing but at that
        // point containingStackView is not defined yet so in that case, we take it as a param.
        let view = defaultView ?? containingStackView
        view.layoutMargins = UIEdgeInsets(top: self.margin, left: 0,
                                          bottom: isDescriptionPresent ? 0 : self.margin, right: 0)
    }

    // MARK: Outer views.
    // TODO: accessibility labels (and parent view)
    // TODO: set line height on all text. http://stackoverflow.com/a/5513730
    lazy var labelContainer: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.titleLabel,
                                                  self.categoryLabel,
                                                  self.urlLabel])
        view.axis = .vertical
        view.spacing = 4

        view.layoutMargins = UIEdgeInsets(top: 0, left: self.margin, bottom: 0, right: self.margin)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()

    lazy var iconInfoViewContainer: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.travelTimeView,
                                                  self.hoursView])
        view.axis = .horizontal
        view.distribution = .fillEqually

        view.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()

    // Ideally we also use a UIStackView but the review dots stretched too
    // far across the screen and it was faster to do it this way.
    lazy var reviewViewContainer: UIStackView = {
        let reviewStackView = UIStackView(arrangedSubviews: [self.yelpReviewView,
                                          self.tripAdvisorReviewView])
        reviewStackView.layoutMargins = UIEdgeInsets(top: 0, left: self.margin, bottom: 0, right: self.margin)
        reviewStackView.spacing = 25
        reviewStackView.axis = .horizontal
        reviewStackView.isLayoutMarginsRelativeArrangement = true
        reviewStackView.distribution = .fillEqually
        return reviewStackView
    }()

    // MARK: Inner views
    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = Colors.detailsViewCardPrimaryText
        view.font = Fonts.detailsViewTitleText
        view.numberOfLines = 0
        view.lineBreakMode = .byWordWrapping
        return view
    }()

    lazy var categoryLabel: UILabel = {
        let view = UILabel()
        view.textColor = Colors.detailsViewCardPrimaryText
        view.font = Fonts.detailsViewCategoryText
        return view
    }()

    lazy var urlLabel: UILabel = {
        let view = UILabel()
        view.textColor = Colors.detailsViewCardLinkText
        view.font = Fonts.detailsViewCategoryText
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var travelTimeView: PlaceDetailsIconInfoView = {
        let view = PlaceDetailsIconInfoView()
        return view
    }()

    lazy var hoursView: PlaceDetailsIconInfoView = {
        let view = PlaceDetailsIconInfoView()
        view.iconView.image = UIImage(named: "icon_times")
        return view
    }()


    lazy var yelpReviewView: ReviewContainerView = {
        let view = ReviewContainerView(color: Colors.yelp, mode: .detailsView)
        view.reviewSiteLogo.image = UIImage(named: "logo_yelp")
        return view
    }()

    lazy var tripAdvisorReviewView: ReviewContainerView = {
        let view = ReviewContainerView(color: Colors.tripAdvisor, mode: .detailsView)
        view.reviewSiteLogo.image = UIImage(named: "logo_ta")
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var wikiDescriptionView = PlaceDetailsDescriptionView(labelText: "Wikipedia summary",
                                                               icon: UIImage(named: "logo_wikipedia"),
                                                               horizontalMargin: 16)

    lazy var yelpDescriptionView = PlaceDetailsDescriptionView(labelText: "Yelp top review",
                                                               icon: UIImage(named: "logo_yelp_small"),
                                                               horizontalMargin: 16)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupShadow()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupShadow() {
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.4
    }

    private func setupViews() {
        backgroundColor = Colors.detailsViewCardBackground
        layer.cornerRadius = 10

        // Note: The constraints of subviews broke when I used leading/trailing, rather than
        // centerX & width. The parent constraints are set with centerX & width - related?
        addSubview(containingStackView)
         NSLayoutConstraint.activate([containingStackView.topAnchor.constraint(equalTo: topAnchor),
                           containingStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                           containingStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
                           containingStackView.trailingAnchor.constraint(equalTo: trailingAnchor)], translatesAutoresizingMaskIntoConstraints: false)

        setupGestureRecognizers()

    }


    private func setupGestureRecognizers() {
        wikiDescriptionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(gestureRecognizer:))))
        yelpDescriptionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(gestureRecognizer:))))
    }

    @objc private func didTap(gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .ended,
            let descriptionView = gestureRecognizer.view as? PlaceDetailsDescriptionView else {
                return
        }

        descriptionView.didTap()
        self.layoutIfNeeded()

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateViewSize()
    }

    // TODO: when else can we call this? layoutSubviews is called when we scroll and we don't want to calculate all this each time...
    private func updateViewSize() {
        delegate?.placeDetailsCardView(cardView: self, heightDidChange: containingStackView.bounds.height)
    }

    func updateUI(forPlace place: Place) {
        // Labels will gracefully collapse on nil.
        titleLabel.text = place.name
        categoryLabel.text = PlaceUtilities.getString(forCategories: place.categories)
        updateURLText(place.url)

        updateHoursUI(place.hours)
        updateDescriptionViewUI(forPlace: place)

        PlaceUtilities.updateReviewUI(fromProvider: place.yelpProvider, onView: yelpReviewView)
        PlaceUtilities.updateReviewUI(fromProvider: place.tripAdvisorProvider, onView: tripAdvisorReviewView)
    }

    private func updateURLText(_ url: String?) {
        guard let url = url else {
            urlLabel.text = nil
            return
        }

        let underlineAttribute = [NSUnderlineStyleAttributeName : NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: url, attributes: underlineAttribute)
        urlLabel.attributedText = underlineAttributedString
    }

    private func updateHoursUI(_ hours: OpenHours?) {
        let (primaryText, secondaryText) = getStringsForOpenHours(hours, forDate: Date())
        hoursView.primaryTextLabel.text = primaryText
        hoursView.secondaryTextLabel.text = secondaryText
    }

    private func updateDescriptionViewUI(forPlace place: Place) {
        let isDescriptionPresent = updateDescriptionViewUIHelper(forText: place.wikiDescription,
                                                                 onView: wikiDescriptionView) ||
                                   updateDescriptionViewUIHelper(forText: place.yelpDescription,
                                                           onView: yelpDescriptionView)
        setContainingStackViewLayoutMargins(isDescriptionPresent: isDescriptionPresent)
    }

    /* Returns true if the view is visible, false otherwise. */
    private func updateDescriptionViewUIHelper(forText text: String?, onView view: PlaceDetailsDescriptionView) -> Bool {
        if let text = text {
            view.isHidden = false
            view.expandableLabel.text = text
            return true
        } else {
//            view.isHidden = true
            view.expandableLabel.text = nil
            return false
        }
    }

    func updateTravelTimesUI(travelTimes: TravelTimes) {
        if let walkingTimeSeconds = travelTimes.walkingTime {
            let walkingTimeMinutes = Int(round(walkingTimeSeconds / 60.0))
            if walkingTimeMinutes <= TravelTimesProvider.MIN_WALKING_TIME {
                if walkingTimeMinutes < TravelTimesProvider.YOU_ARE_HERE_WALKING_TIME {
                    self.travelTimeView.primaryTextLabel.text = "You are here!"
                    self.travelTimeView.secondaryTextLabel.text = nil
                    self.travelTimeView.iconView.image = nil
                } else {
                    self.travelTimeView.primaryTextLabel.text = "\(walkingTimeMinutes) min"
                    self.travelTimeView.secondaryTextLabel.text = "Walking"
                    self.travelTimeView.iconView.image = UIImage(named: "icon_walkingdist")
                }
                return
            }
        }

        if let drivingTimeSeconds = travelTimes.drivingTime {
            let drivingTimeMinutes = Int(round(drivingTimeSeconds / 60.0))
            self.travelTimeView.primaryTextLabel.text = "\(drivingTimeMinutes) min"
            self.travelTimeView.secondaryTextLabel.text = "Driving"
            self.travelTimeView.iconView.image = UIImage(named: "icon_drivingdist")
        }
    }

    private func getStringsForOpenHours(_ openHours: OpenHours?, forDate date: Date) -> (primary: String, secondary: String) {
        guard let openHours = openHours else {
            // if hours is nil, we assume this place has no listed hours (e.g. beach).
            return ("Not sure", "Closing time")
        }

        let innerHours = openHours.hours
        let day = DayOfWeek.forDate(date)
        guard let (open, close) = innerHours[day] else {
            print("lol unexpectedly no hours for \(date)")
            return ("No hours", "For Today") // TODO: probably closed today - how best to handle?
        }

        if date > open {
            let closeTimeStr = openHours.getCloseTimeString(forDate: date)
            if date < close {
                return (closeTimeStr, "Closing time")
            }
            print("lol venue unexpectedly already closed for \(date) and closing \(close)")
            return ("Closed", "at \(closeTimeStr)") // TODO: already closed - how best to handle?
        }

        let openTimeStr = openHours.getOpenTimeString(forDate: date)
        return ("Closed", "Opens at \(openTimeStr)")
    }
}
