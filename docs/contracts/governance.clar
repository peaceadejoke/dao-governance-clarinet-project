;; ------------------------------------------------------------
;; DAO Governance Contract - Fully Clean, ASCII-only Clarity
;; ------------------------------------------------------------

;; Data Variables
(define-data-var last-proposal-id uint u0)

;; Stores proposals
(define-map proposals uint
  {
    proposer: principal,
    description: (string-utf8 256),
    yes: uint,
    no: uint,
    end-block: uint
  }
)

;; Track votes: map key (proposal-id, voter)
(define-map votes
  { id: uint, voter: principal }
  bool
)

;; Error codes
(define-constant ERR-NOT-FOUND u404)
(define-constant ERR-ALREADY-VOTED u409)
(define-constant ERR-NOT-ENDED u408)
(define-constant ERR-FAILED u410)

;; Next proposal ID
(define-private (next-id)
  (let ((current (var-get last-proposal-id)))
    (var-set last-proposal-id (+ current u1))
    (+ current u1)
  )
)

;; ------------------------------------------------------------
;; Read-only helpers
;; ------------------------------------------------------------

(define-read-only (get-proposal (id uint))
  (match (map-get? proposals id)
    proposal (ok proposal)
    (err ERR-NOT-FOUND)
  )
)

(define-read-only (is-active (id uint))
  (match (map-get? proposals id)
    proposal (ok (>= (get end-block proposal) block-height))
    (err ERR-NOT-FOUND)
  )
)

;; ------------------------------------------------------------
;; Create proposal
;; ------------------------------------------------------------

(define-public (create-proposal (description (string-utf8 256)) (duration uint))
  (let ((new-id (next-id)) (end (+ block-height duration)))
    (map-set proposals new-id
      {
        proposer: tx-sender,
        description: description,
        yes: u0,
        no: u0,
        end-block: end
      }
    )
    (ok new-id)
  )
)

;; ------------------------------------------------------------
;; Vote
;; ------------------------------------------------------------

(define-public (vote (id uint) (choice bool))
  (match (map-get? proposals id)
    proposal
      (begin
        ;; ensure active
        (asserts! (>= (get end-block proposal) block-height) (err ERR-NOT-ENDED))
        
        ;; prevent double voting
        (let ((vote-key { id: id, voter: tx-sender }))
          (match (map-get? votes vote-key)
            voted (err ERR-ALREADY-VOTED)
            (begin
              ;; record vote
              (map-set votes vote-key true)

              ;; update proposal counts
              (if choice
                  (map-set proposals id
                    {
                      proposer: (get proposer proposal),
                      description: (get description proposal),
                      yes: (+ (get yes proposal) u1),
                      no: (get no proposal),
                      end-block: (get end-block proposal)
                    }
                  )
                  (map-set proposals id
                    {
                      proposer: (get proposer proposal),
                      description: (get description proposal),
                      yes: (get yes proposal),
                      no: (+ (get no proposal) u1),
                      end-block: (get end-block proposal)
                    }
                  )
              )

              (ok true)
            )
          )
        )
      )
    (err ERR-NOT-FOUND)
  )
)

;; ------------------------------------------------------------
;; Check result
;; ------------------------------------------------------------

(define-read-only (result (id uint))
  (match (map-get? proposals id)
    proposal
      (let ((yes (get yes proposal)) (no (get no proposal)))
        (if (> yes no)
            (ok { passed: true, yes: yes, no: no })
            (ok { passed: false, yes: yes, no: no })
        )
      )
    (err ERR-NOT-FOUND)
  )
)

;; ------------------------------------------------------------
;; Execute proposal
;; ------------------------------------------------------------

(define-public (execute-proposal (id uint))
  (match (map-get? proposals id)
    proposal
      (begin
        ;; must be ended
        (asserts! (< (get end-block proposal) block-height) (err ERR-NOT-ENDED))

        ;; must have passed
        (asserts! (> (get yes proposal) (get no proposal)) (err ERR-FAILED))

        ;; execution result placeholder
        (ok {
              executed: true,
              proposer: (get proposer proposal)
            })
      )
    (err ERR-NOT-FOUND)
  )
)
