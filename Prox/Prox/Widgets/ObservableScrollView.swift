/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ObservableScrollView: UIScrollView {

    var onContentSizeUpdated: ((CGSize) -> Void)?

    init() {
        super.init(frame: .zero)
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var contentSize: CGSize {
        didSet { onContentSizeUpdated?(contentSize) }
    }
}
