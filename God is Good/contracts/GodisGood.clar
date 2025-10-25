;; contracts/godisgood.clar
;; GodisGood - Karma Raffle
;; - Create campaigns
;; - Add acts (short descriptions)
;; - Community members vote for acts (one vote per act per voter)
;; - Campaign creator closes campaign
;; - Highest-vote act wins the campaign (deterministic, tiebreak = earliest act)

(define-data-var campaign-count uint u0)

;; Campaigns: id -> { creator, title, act-count, total-votes, open, leading-act, leading-votes, winner (optional principal) }
(define-map campaigns
    { id: uint }
    {
        creator: principal,
        title: (string-ascii 64),
        act-count: uint,
        total-votes: uint,
        open: bool,
        leading-act: uint,
        leading-votes: uint,
        winner: (optional principal),
    }
)

;; Acts: (campaign,id) -> { actor, description, votes }
(define-map acts
    {
        campaign: uint,
        id: uint,
    }
    {
        actor: principal,
        description: (string-ascii 128),
        votes: uint,
    }
)

;; Records that a voter voted for an act: key -> marker (prevents double-vote)
(define-map voted
    {
        campaign: uint,
        act: uint,
        voter: principal,
    }
    { marker: bool }
)

;; Error codes
(define-constant ERR-NO-CAMPAIGN u100)
(define-constant ERR-CAMPAIGN-closed u101)
(define-constant ERR-ACT-NOT-FOUND u102)
(define-constant ERR-ALREADY-VOTED u103)
(define-constant ERR-NOT-CREATOR u104)
(define-constant ERR-NO-VOTES u105)

;; Create a new campaign with a title -> returns campaign id
(define-public (create-campaign (title (string-ascii 64)))
    (let ((id (+ u1 (var-get campaign-count))))
        (begin
            (var-set campaign-count id)
            (map-set campaigns { id: id } {
                creator: tx-sender,
                title: title,
                act-count: u0,
                total-votes: u0,
                open: true,
                leading-act: u0,
                leading-votes: u0,
                winner: none,
            })
            (ok id)
        )
    )
)

;; Add an act (a short description) to an open campaign -> returns act id
(define-public (add-act
        (campaign-id uint)
        (text (string-ascii 128))
    )
    (let ((c (map-get? campaigns { id: campaign-id })))
        (begin
            (asserts! (is-some c) (err ERR-NO-CAMPAIGN))
            (let (
                    (campaign (unwrap! c (err ERR-NO-CAMPAIGN)))
                    (next-id (+ u1 (get act-count (unwrap! c (err ERR-NO-CAMPAIGN)))))
                )
                (asserts! (get open campaign) (err ERR-CAMPAIGN-closed))
                (map-set acts {
                    campaign: campaign-id,
                    id: next-id,
                } {
                    actor: tx-sender,
                    description: text,
                    votes: u0,
                })
                ;; update act-count in campaign
                (map-set campaigns { id: campaign-id } {
                    creator: (get creator campaign),
                    title: (get title campaign),
                    act-count: next-id,
                    total-votes: (get total-votes campaign),
                    open: (get open campaign),
                    leading-act: (get leading-act campaign),
                    leading-votes: (get leading-votes campaign),
                    winner: (get winner campaign),
                })
                (ok next-id)
            )
        )
    )
)

;; Vote for a specific act (one vote per voter per act)
(define-public (vote
        (campaign-id uint)
        (act-id uint)
    )
    (let (
            (c (map-get? campaigns { id: campaign-id }))
            (a (map-get? acts {
                campaign: campaign-id,
                id: act-id,
            }))
            (already (map-get? voted {
                campaign: campaign-id,
                act: act-id,
                voter: tx-sender,
            }))
        )
        (begin
            (asserts! (is-some c) (err ERR-NO-CAMPAIGN))
            (asserts! (is-some a) (err ERR-ACT-NOT-FOUND))
            (asserts! (is-none already) (err ERR-ALREADY-VOTED))

            (let (
                    (campaign (unwrap! c (err ERR-NO-CAMPAIGN)))
                    (act (unwrap! a (err ERR-ACT-NOT-FOUND)))
                )
                (asserts! (get open campaign) (err ERR-CAMPAIGN-closed))

                ;; increment act votes
                (let ((new-act-votes (+ (get votes act) u1)))
                    (map-set acts {
                        campaign: campaign-id,
                        id: act-id,
                    } {
                        actor: (get actor act),
                        description: (get description act),
                        votes: new-act-votes,
                    })

                    ;; record voter to prevent double-vote
                    (map-set voted {
                        campaign: campaign-id,
                        act: act-id,
                        voter: tx-sender,
                    } { marker: true }
                    )

                    ;; update campaign total votes
                    (let ((new-total (+ (get total-votes campaign) u1)))
                        ;; possibly update leading-act if this act now leads
                        (if (> new-act-votes (get leading-votes campaign))
                            (map-set campaigns { id: campaign-id } {
                                creator: (get creator campaign),
                                title: (get title campaign),
                                act-count: (get act-count campaign),
                                total-votes: new-total,
                                open: (get open campaign),
                                leading-act: act-id,
                                leading-votes: new-act-votes,
                                winner: (get winner campaign),
                            })
                            ;; else only update total-votes
                            (map-set campaigns { id: campaign-id } {
                                creator: (get creator campaign),
                                title: (get title campaign),
                                act-count: (get act-count campaign),
                                total-votes: new-total,
                                open: (get open campaign),
                                leading-act: (get leading-act campaign),
                                leading-votes: (get leading-votes campaign),
                                winner: (get winner campaign),
                            })
                        )
                    )
                    (ok true)
                )
            )
        )
    )
)

;; Campaign creator closes the campaign (no more acts or votes)
(define-public (close-campaign (campaign-id uint))
    (let ((c (map-get? campaigns { id: campaign-id })))
        (begin
            (asserts! (is-some c) (err ERR-NO-CAMPAIGN))
            (let ((campaign (unwrap! c (err ERR-NO-CAMPAIGN))))
                (asserts! (is-eq tx-sender (get creator campaign))
                    (err ERR-NOT-CREATOR)
                )
                (map-set campaigns { id: campaign-id } {
                    creator: (get creator campaign),
                    title: (get title campaign),
                    act-count: (get act-count campaign),
                    total-votes: (get total-votes campaign),
                    open: false,
                    leading-act: (get leading-act campaign),
                    leading-votes: (get leading-votes campaign),
                    winner: (get winner campaign),
                })
                (ok true)
            )
        )
    )
)

;; Select winner (only campaign creator can trigger once closed).
;; Winner = actor of leading-act (highest votes). Must have at least 1 vote.
(define-public (select-winner (campaign-id uint))
    (let ((c (map-get? campaigns { id: campaign-id })))
        (begin
            (asserts! (is-some c) (err ERR-NO-CAMPAIGN))
            (let ((campaign (unwrap! c (err ERR-NO-CAMPAIGN))))
                (asserts! (is-eq tx-sender (get creator campaign))
                    (err ERR-NOT-CREATOR)
                )
                (asserts! (not (get open campaign)) (err ERR-CAMPAIGN-closed))
                (asserts! (> (get total-votes campaign) u0) (err ERR-NO-VOTES))
                (let ((winner-act-id (get leading-act campaign)))
                    (asserts! (> winner-act-id u0) (err ERR-NO-VOTES))
                    (let ((a (map-get? acts {
                            campaign: campaign-id,
                            id: winner-act-id,
                        })))
                        (asserts! (is-some a) (err ERR-ACT-NOT-FOUND))
                        (let (
                                (act (unwrap! a (err ERR-ACT-NOT-FOUND)))
                                (winner-principal (get actor (unwrap! a (err ERR-ACT-NOT-FOUND))))
                            )
                            ;; record winner on campaign
                            (map-set campaigns { id: campaign-id } {
                                creator: (get creator campaign),
                                title: (get title campaign),
                                act-count: (get act-count campaign),
                                total-votes: (get total-votes campaign),
                                open: (get open campaign),
                                leading-act: (get leading-act campaign),
                                leading-votes: (get leading-votes campaign),
                                winner: (some winner-principal),
                            })
                            (ok winner-principal)
                        )
                    )
                )
            )
        )
    )
)

;; -----------------------
;; Read-only views
;; -----------------------

(define-read-only (get-campaign (campaign-id uint))
    (map-get? campaigns { id: campaign-id })
)

(define-read-only (get-act
        (campaign-id uint)
        (act-id uint)
    )
    (map-get? acts {
        campaign: campaign-id,
        id: act-id,
    })
)

(define-read-only (get-leading (campaign-id uint))
    (let ((c (map-get? campaigns { id: campaign-id })))
        (if (is-some c)
            (let ((campaign (unwrap! c (err ERR-NO-CAMPAIGN))))
                (if (> (get leading-act campaign) u0)
                    (map-get? acts {
                        campaign: campaign-id,
                        id: (get leading-act campaign),
                    })
                    none
                )
            )
            none
        )
    )
)

(define-read-only (get-winner (campaign-id uint))
    (let ((c (map-get? campaigns { id: campaign-id })))
        (if (is-some c)
            (get winner (unwrap! c (err ERR-NO-CAMPAIGN)))
            none
        )
    )
)