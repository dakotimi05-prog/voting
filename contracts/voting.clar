;; contracts/voting.clar
;; Simple On-Chain Voting System
;; - Users create proposals
;; - Anyone can vote yes/no
;; - Results stored on-chain

(define-data-var proposal-count uint u0)

(define-map proposals 
  { id: uint } 
  { creator: principal, title: (string-ascii 100), yes: uint, no: uint, open: bool }
)

(define-map votes 
  { id: uint, voter: principal } 
  { choice: bool }
)

(define-constant ERR-NO-PROPOSAL u100)
(define-constant ERR-ALREADY-VOTED u101)
(define-constant ERR-CLOSED u102)

;; --- create a new proposal ---
(define-public (create-proposal (title (string-ascii 100)))
  (let ((id (+ u1 (var-get proposal-count))))
    (begin
      (var-set proposal-count id)
      (map-set proposals { id: id } { creator: tx-sender, title: title, yes: u0, no: u0, open: true })
      (ok id)
    )
  )
)

;; --- cast a vote ---
(define-public (vote (id uint) (choice bool))
  (let (
    (prop (map-get? proposals { id: id }))
  )
    (begin
      (asserts! (is-some prop) (err ERR-NO-PROPOSAL))
      (asserts! (get open (unwrap! prop (err ERR-NO-PROPOSAL))) (err ERR-CLOSED))
      (asserts! (is-none (map-get? votes { id: id, voter: tx-sender })) (err ERR-ALREADY-VOTED))
      (map-set votes { id: id, voter: tx-sender } { choice: choice })
      (if choice
        (map-set proposals { id: id }
          { creator: (get creator (unwrap! prop (err u999)))
            title: (get title (unwrap! prop (err u999)))
            yes: (+ (get yes (unwrap! prop (err u999))) u1)
            no: (get no (unwrap! prop (err u999)))
            open: true })
        (map-set proposals { id: id }
          { creator: (get creator (unwrap! prop (err u999)))
            title: (get title (unwrap! prop (err u999)))
            yes: (get yes (unwrap! prop (err u999)))
            no: (+ (get no (unwrap! prop (err u999))) u1)
            open: true })
      )
      (ok true)
    )
  )
)

;; --- close proposal (creator only) ---
(define-public (close (id uint))
  (let ((prop (map-get? proposals { id: id })))
    (begin
      (asserts! (is-some prop) (err ERR-NO-PROPOSAL))
      (asserts! (is-eq tx-sender (get creator (unwrap! prop (err ERR-NO-PROPOSAL)))) (err ERR-NO-PROPOSAL))
      (map-set proposals { id: id }
        { creator: (get creator (unwrap! prop (err u999)))
          title: (get title (unwrap! prop (err u999)))
          yes: (get yes (unwrap! prop (err u999)))
          no: (get no (unwrap! prop (err u999)))
          open: false })
      (ok true)
    )
  )
)

;; --- views ---
(define-read-only (get-proposal (id uint))
  (map-get? proposals { id: id })
)

(define-read-only (get-count)
  (var-get proposal-count)
)
