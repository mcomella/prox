/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class PlaceDetailsIconInfoView: UIView {

    lazy var iconView: UIImageView = {
        let view = UIImageView()
        // TODO: view.contentMode (scaling)
        return view
    }()

    // Contains the labels, providing an anchor on the widest text for the icon.
    lazy var labelContainer: UIView = UIView()

    // TODO: line count & truncation
    lazy var primaryTextLabel: UILabel = {
        let view = UILabel()
        view.textColor = Colors.detailsViewCardPrimaryText
        view.font = Fonts.detailsViewIconInfoPrimaryText
        view.textAlignment = .center
        return view
    }()

    lazy var secondaryTextLabel: UILabel = {
        let view = UILabel()
        view.textColor = Colors.detailsViewCardSecondaryText
        view.font = Fonts.detailsViewIconInfoSecondaryText
        view.textAlignment = .center
        return view
    }()

    lazy var forwardArrowView = UIImageView(image: UIImage(named: "icon_forward"))

    private lazy var loadingSpinner: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()

    var isLoading = false {
        didSet {
            if isLoading {
                loadingSpinner.startAnimating()
                forwardArrowView.isHidden = true
            } else {
                loadingSpinner.stopAnimating()
                forwardArrowView.isHidden = false
            }
        }
    }

    let enableForwardArrow: Bool

    // We hide primary because we want secondary text style.
    var isPrimaryTextLabelHidden = false {
        didSet {
            if oldValue != isPrimaryTextLabelHidden { setPrimaryTextLabelHidden(isPrimaryTextLabelHidden) }
        }
    }

    fileprivate var secondaryTextLabelFullHeightConstraint: NSLayoutConstraint!

    init(enableForwardArrow: Bool) {
        self.enableForwardArrow = enableForwardArrow
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        var constraints = setupLabelContainerSubviews()
        addSubview(labelContainer)
        constraints += [labelContainer.topAnchor.constraint(equalTo: topAnchor),
                        labelContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
                        labelContainer.bottomAnchor.constraint(equalTo: bottomAnchor)]

        addSubview(iconView)
        constraints += [iconView.centerYAnchor.constraint(equalTo: labelContainer.centerYAnchor),
                        iconView.trailingAnchor.constraint(equalTo: labelContainer.leadingAnchor, constant: -6)]

        if enableForwardArrow {
            addSubview(forwardArrowView)
            constraints += [forwardArrowView.centerYAnchor.constraint(equalTo: labelContainer.centerYAnchor),
                            forwardArrowView.leadingAnchor.constraint(equalTo: labelContainer.trailingAnchor, constant: 8)]
        }

        addSubview(loadingSpinner)
        constraints += [loadingSpinner.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     loadingSpinner.centerYAnchor.constraint(equalTo: centerYAnchor),
                                     loadingSpinner.widthAnchor.constraint(equalToConstant: 20),
                                     loadingSpinner.heightAnchor.constraint(equalToConstant: 20)]

        NSLayoutConstraint.activate(constraints, translatesAutoresizingMaskIntoConstraints: false)
    }

    private func setupLabelContainerSubviews() -> [NSLayoutConstraint] {
        secondaryTextLabelFullHeightConstraint = secondaryTextLabel.heightAnchor.constraint(equalTo: labelContainer.heightAnchor, multiplier: 1)

        labelContainer.addSubview(secondaryTextLabel)
        var constraints: [NSLayoutConstraint] = [secondaryTextLabel.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
                                                 secondaryTextLabel.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),
                                                 secondaryTextLabel.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor)]

        labelContainer.addSubview(primaryTextLabel)
        constraints += [primaryTextLabel.topAnchor.constraint(equalTo: labelContainer.topAnchor),
                        primaryTextLabel.leadingAnchor.constraint(equalTo: secondaryTextLabel.leadingAnchor),
                        primaryTextLabel.trailingAnchor.constraint(equalTo: secondaryTextLabel.trailingAnchor),
                        primaryTextLabel.bottomAnchor.constraint(equalTo: secondaryTextLabel.topAnchor)]

        return constraints
    }

    private func setPrimaryTextLabelHidden(_ isHidden: Bool) {
        if isHidden {
            primaryTextLabel.isHidden = true
            secondaryTextLabelFullHeightConstraint.isActive = true
        } else {
            primaryTextLabel.isHidden = false
            secondaryTextLabelFullHeightConstraint.isActive = false
        }
    }
}
