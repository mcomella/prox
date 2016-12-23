/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Firebase

private var continuingObservers = [(url: String, handle: FIRDatabaseHandle)]()

extension FIRDatabaseReference {

    /*
     * Clears all observers set with `observeSingleEventButDownloadUpdates(of:with)`.
     *
     * The expected use case is to clear the observers when the app is moved into the background.
     * This is FRAGILE: it's easy to forget to call this method. If this method isn't called,
     * observers will continue to run in the background and will continue to accumulate, wasting
     * CPU and memory resources.
     */
    class func clearContinuingObservers() {
        let db = FIRDatabase.database()
        for (url, handle) in continuingObservers {
            let dbRef = db.reference(fromURL: url)
            dbRef.removeObserver(withHandle: handle)
        }
        continuingObservers.removeAll()
    }

    /*
     * Observes an event, calling the callback only for the initial value, which comes from the cache or,
     * if no data is cached, the initially downloaded value. Unlike `observeSingleEvent(of:with)`,
     * the observer remains attached under the hood, allowing Firebase to update cached objects. For
     * context on how Firebase updates cached objects, see http://stackoverflow.com/a/24516952
     *
     * NOTE: since we query, then update the value, at least one query has to be returned with
     * outdated data before the data will be updated. An untested, possible fix would call
     * `keepSynced(true)` before one-off querying and disabling it afterwards (or in
     * clearContinuingObservers). However, this could delete state set by the caller and there's no
     * way to know a node's `keepSynced` value.
     *
     * Don't forget to clean up the listener, either with `removeObserverWithHandle` or `clearContinuingObservers`.
     */
    @discardableResult
    func observeSingleEventButDownloadUpdates(of: FIRDataEventType, with callback: @escaping (FIRDataSnapshot) -> Void) -> FIRDatabaseHandle {
        var wasCallbackCalled = false
        let handle = observe(.value, with: { data in
            guard !wasCallbackCalled else { return }
            wasCallbackCalled = true
            callback(data)
        })

        continuingObservers.append((url, handle))
        return handle
    }
}
