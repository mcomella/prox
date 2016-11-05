/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

fileprivate enum UIMode {
    case collapsed, expanded
}

class PlaceDetailsDescriptionView: HorizontalLineView {

    private let CollapseExpandSeconds = 1.0

    let horizontalMargin: CGFloat

    fileprivate var uiMode: UIMode = .collapsed
    var collapsedConstraints: [NSLayoutConstraint]!
    var expandedConstraints: [NSLayoutConstraint]!

    lazy var logoView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    lazy var label: UILabel = {
        let view = UILabel()
        view.font = Fonts.detailsViewDescriptionTitle
        return view
    }()

    // TODO: icon
    lazy var expandButton: UIImageView = UIImageView()

    lazy var expandableLabel: UILabel = {
        let view = UILabel()
        view.font = Fonts.detailsViewDescriptionText
        view.textColor = Colors.detailsViewCardSecondaryText
        view.numberOfLines = 0
        return view
    }()

    lazy var descriptionTitleView: UIView = UIView()

    init(labelText: String,
         icon: UIImage?,
         horizontalMargin: CGFloat) {
        self.horizontalMargin = horizontalMargin
        super.init(frame: .zero)

        logoView.image = icon
        label.text = labelText
        backgroundColor = .clear

        setupSubviews()
        setupLine()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var expandableLabelHeightConstraint: NSLayoutConstraint = {
        return self.expandableLabel.heightAnchor.constraint(equalToConstant: 0)
    }()

    lazy var expandableLabelBottomConstraint: NSLayoutConstraint = {
        return self.expandableLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
    }()

    private func setupSubviews() {
        addSubview(descriptionTitleView)
        var constraints = [descriptionTitleView.topAnchor.constraint(equalTo: topAnchor),
                           descriptionTitleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalMargin),
                           descriptionTitleView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalMargin),
                           descriptionTitleView.heightAnchor.constraint(equalToConstant: 56)]

        descriptionTitleView.addSubview(logoView)
        constraints += [logoView.leadingAnchor.constraint(equalTo: descriptionTitleView.leadingAnchor),
                            logoView.centerYAnchor.constraint(equalTo: descriptionTitleView.centerYAnchor),
                           logoView.widthAnchor.constraint(equalToConstant: 16),
                           logoView.heightAnchor.constraint(equalToConstant: 16)]

        descriptionTitleView.addSubview(label)
        constraints += [label.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
                        label.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: horizontalMargin),
                        label.trailingAnchor.constraint(equalTo: expandButton.leadingAnchor, constant: -horizontalMargin)]

        descriptionTitleView.addSubview(expandButton)
        constraints += [expandButton.centerYAnchor.constraint(equalTo: logoView.centerYAnchor),
                        expandButton.trailingAnchor.constraint(equalTo: descriptionTitleView.trailingAnchor),
                        expandButton.widthAnchor.constraint(equalToConstant: 16),
                        expandButton.heightAnchor.constraint(equalToConstant: 16)]

        addSubview(expandableLabel)
        constraints += [expandableLabel.topAnchor.constraint(equalTo: descriptionTitleView.bottomAnchor),
                        expandableLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalMargin),
                        expandableLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalMargin),
                        expandableLabelHeightConstraint,
                        expandableLabelBottomConstraint]

        NSLayoutConstraint.activate(constraints, translatesAutoresizingMaskIntoConstraints: false)
    }

    private func setupLine() {
        color = Colors.detailsViewCardSeparator
        startX = 0.0
        startY = 0.0
        endY = 0.0
    }

    func didTap() {
        switch uiMode {
        case .collapsed:
            uiMode = .expanded
            expandView()
        case .expanded:
            uiMode = .collapsed
            collapseView()
        }
    }

    private func expandView() {
        expandableLabelHeightConstraint.isActive = false
        expandableLabelBottomConstraint.constant = -10
        self.layoutIfNeeded()
    }

    private func collapseView() {
        expandableLabelBottomConstraint.constant = 0
        expandableLabelHeightConstraint.isActive = true
        self.layoutIfNeeded()
    }
}
