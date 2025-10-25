;; match-app
;; Short & error-free Clarity contract for a decentralized dating app

(define-data-var profile-counter uint u0)

(define-map profiles
    { id: uint }
    {
        user: principal,
        bio: (string-ascii 50),
        match-id: (optional uint),
        status: (string-ascii 10),
    }
)

;; Create a user profile
(define-public (create-profile (bio (string-ascii 50)))
    (let ((id (var-get profile-counter)))
        (map-set profiles { id: id } {
            user: tx-sender,
            bio: bio,
            match-id: none,
            status: "active",
        })
        (var-set profile-counter (+ id u1))
        (ok id)
    )
)

;; Propose a match between two profiles
(define-public (propose-match
        (profile-id uint)
        (target-id uint)
    )
    (match (map-get? profiles { id: profile-id })
        sender-profile
        (match (map-get? profiles { id: target-id })
            target-profile
            (if (and
                    (is-eq (get status sender-profile) "active")
                    (is-eq (get status target-profile) "active")
                    (is-none (get match-id sender-profile))
                    (is-none (get match-id target-profile))
                )
                (begin
                    (map-set profiles { id: profile-id } {
                        user: (get user sender-profile),
                        bio: (get bio sender-profile),
                        match-id: (some target-id),
                        status: "pending",
                    })
                    (ok "Match proposed")
                )
                (err u1)
            )
            ;; not active or already matched
            (err u2)
        )
        ;; target not found
        (err u3)
    )
    ;; sender not found
)

;; Accept a match proposal
(define-public (accept-match (profile-id uint))
    (match (map-get? profiles { id: profile-id })
        profile
        (if (and (is-eq (get status profile) "pending") (is-eq tx-sender (get user profile)))
            (match (get match-id profile)
                target-id
                (match (map-get? profiles { id: target-id })
                    target-profile (begin
                        (map-set profiles { id: profile-id } {
                            user: (get user profile),
                            bio: (get bio profile),
                            match-id: (get match-id profile),
                            status: "matched",
                        })
                        (map-set profiles { id: target-id } {
                            user: (get user target-profile),
                            bio: (get bio target-profile),
                            match-id: (some profile-id),
                            status: "matched",
                        })
                        (ok "Match accepted")
                    )
                    (err u4)
                )
                ;; target not found
                (err u5)
            )
            ;; no match proposed
            (err u6)
        )
        ;; not pending or not user
        (err u7)
    )
    ;; profile not found
)