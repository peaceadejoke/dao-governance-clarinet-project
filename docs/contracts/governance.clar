;; ------------------------------------------------------------
;; DAO Governance Contract - Phase 3: Enhanced Security & Features
;; ------------------------------------------------------------

;; Constants
(define-constant contract-owner tx-sender)
(define-constant MIN-QUORUM u100) ;; Minimum votes required
(define-constant MIN-APPROVAL-PERCENT u51) ;; 51% approval needed

;; Error codes
(define-constant ERR-NOT-FOUND u404)
(define-constant ERR-ALREADY-VOTED u409)
(define-constant ERR-NOT-ENDED u408)
(define-constant ERR-FAILED u410)
(define-constant ERR-NOT-AUTHORIZED u401)
(define-constant ERR-INVALID-DURATION u411)
(define-constant ERR-ALREADY-EXECUTED u412)
(define-constant ERR-QUORUM-NOT-MET u413)
(define-constant ERR-PROPOSAL-ACTIVE u414)
(define-constant ERR-INVALID-TOKEN-AMOUNT u415)

;; Data Variables
(define-data-var last-proposal-id uint u0)
(define-data-var governance-token principal tx-sender)
(define-data-var min-proposal-threshold uint u1000) ;; Min tokens to create proposal

;; Proposal structure with enhanced fields
(define-map proposals uint
  {
    proposer: principal,
    description: (string-utf8 256),
    yes-votes: uint,
    no-votes: uint,
    total-vote-weight: uint,
    start-block: uint,
    end-block: uint,
    executed: bool,
    canceled: bool,
    execution-delay: uint
  }
)

;; Track weighted votes: stores voter's token weight
(define-map votes
  { id: uint, voter: principal }
  { weight: uint, choice: bool }
)

;; Delegation tracking
(define-map delegations
  principal
  (optional principal)
)

;; Proposal categories for organization
(define-map proposal-categories uint (string-utf8 50))

;; Time-lock for executed proposals
(define-map execution-timelock uint uint)

;; ------------------------------------------------------------
;; Admin Functions
;; ------------------------------------------------------------

(define-public (set-governance-token (token principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err ERR-NOT-AUTHORIZED))
    (var-set governance-token token)
    (ok true)
  )
)

(define-public (set-proposal-threshold (threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err ERR-NOT-AUTHORIZED))
    (var-set min-proposal-threshold threshold)
    (ok true)
  )
)

;; ------------------------------------------------------------
;; Delegation Functions
;; ------------------------------------------------------------

(define-public (delegate-votes (to principal))
  (begin
    (asserts! (not (is-eq tx-sender to)) (err ERR-NOT-AUTHORIZED))
    (map-set delegations tx-sender (some to))
    (print { event: "vote-delegated", from: tx-sender, to: to })
    (ok true)
  )
)

(define-public (revoke-delegation)
  (begin
    (map-set delegations tx-sender none)
    (print { event: "delegation-revoked", voter: tx-sender })
    (ok true)
  )
)

(define-read-only (get-delegate (voter principal))
  (default-to none (map-get? delegations voter))
)

;; ------------------------------------------------------------
;; Helper Functions
;; ------------------------------------------------------------

(define-private (next-id)
  (let ((current (var-get last-proposal-id)))
    (var-set last-proposal-id (+ current u1))
    (+ current u1)
  )
)

(define-private (get-voting-power (voter principal))
  ;; In production, this would call the governance token contract
  ;; For now, returns a placeholder value
  u100
)

(define-private (calculate-approval-rate (yes uint) (no uint))
  (if (is-eq (+ yes no) u0)
      u0
      (/ (* yes u100) (+ yes no))
  )
)

;; ------------------------------------------------------------
;; Read-only Functions
;; ------------------------------------------------------------

(define-read-only (get-proposal (id uint))
  (match (map-get? proposals id)
    proposal (ok proposal)
    (err ERR-NOT-FOUND)
  )
)

(define-read-only (get-vote (id uint) (voter principal))
  (ok (map-get? votes { id: id, voter: voter }))
)

(define-read-only (is-active (id uint))
  (match (map-get? proposals id)
    proposal 
      (ok (and 
            (>= block-height (get start-block proposal))
            (<= block-height (get end-block proposal))
            (not (get canceled proposal))
          ))
    (err ERR-NOT-FOUND)
  )
)

(define-read-only (can-execute (id uint))
  (match (map-get? proposals id)
    proposal
      (let 
        (
          (voting-ended (> block-height (get end-block proposal)))
          (not-executed (not (get executed proposal)))
          (not-canceled (not (get canceled proposal)))
          (passed (> (get yes-votes proposal) (get no-votes proposal)))
          (quorum-met (>= (get total-vote-weight proposal) MIN-QUORUM))
          (approval-rate (calculate-approval-rate 
                          (get yes-votes proposal) 
                          (get no-votes proposal)))
        )
        (ok (and voting-ended not-executed not-canceled passed quorum-met 
                 (>= approval-rate MIN-APPROVAL-PERCENT)))
      )
    (err ERR-NOT-FOUND)
  )
)

(define-read-only (get-proposal-stats (id uint))
  (match (map-get? proposals id)
    proposal
      (ok {
        total-votes: (+ (get yes-votes proposal) (get no-votes proposal)),
        approval-rate: (calculate-approval-rate 
                        (get yes-votes proposal) 
                        (get no-votes proposal)),
        quorum-met: (>= (get total-vote-weight proposal) MIN-QUORUM),
        time-remaining: (if (<= block-height (get end-block proposal))
                            (- (get end-block proposal) block-height)
                            u0)
      })
    (err ERR-NOT-FOUND)
  )
)

;; ------------------------------------------------------------
;; Create Proposal
;; ------------------------------------------------------------

(define-public (create-proposal 
                (description (string-utf8 256)) 
                (duration uint)
                (category (string-utf8 50))
                (execution-delay uint))
  (let 
    (
      (proposer-balance (get-voting-power tx-sender))
      (new-id (next-id))
      (start block-height)
      (end (+ block-height duration))
    )
    ;; Security checks
    (asserts! (> duration u10) (err ERR-INVALID-DURATION))
    (asserts! (<= duration u14400) (err ERR-INVALID-DURATION)) ;; Max ~100 days
    (asserts! (>= proposer-balance (var-get min-proposal-threshold)) 
              (err ERR-INVALID-TOKEN-AMOUNT))
    
    ;; Create proposal
    (map-set proposals new-id
      {
        proposer: tx-sender,
        description: description,
        yes-votes: u0,
        no-votes: u0,
        total-vote-weight: u0,
        start-block: start,
        end-block: end,
        executed: false,
        canceled: false,
        execution-delay: execution-delay
      }
    )
    
    ;; Set category
    (map-set proposal-categories new-id category)
    
    (print { 
      event: "proposal-created", 
      id: new-id, 
      proposer: tx-sender,
      category: category 
    })
    (ok new-id)
  )
)

;; ------------------------------------------------------------
;; Voting with Token Weight
;; ------------------------------------------------------------

(define-public (vote (id uint) (choice bool))
  (let
    (
      (voter-power (get-voting-power tx-sender))
      (vote-key { id: id, voter: tx-sender })
    )
    (match (map-get? proposals id)
      proposal
        (begin
          ;; Security checks
          (asserts! (>= block-height (get start-block proposal)) (err ERR-NOT-ENDED))
          (asserts! (<= block-height (get end-block proposal)) (err ERR-NOT-ENDED))
          (asserts! (not (get canceled proposal)) (err ERR-FAILED))
          (asserts! (> voter-power u0) (err ERR-INVALID-TOKEN-AMOUNT))
          
          ;; Check for existing vote
          (match (map-get? votes vote-key)
            existing-vote (err ERR-ALREADY-VOTED)
            (begin
              ;; Record weighted vote
              (map-set votes vote-key { weight: voter-power, choice: choice })
              
              ;; Update proposal with weighted counts
              (map-set proposals id
                (merge proposal {
                  yes-votes: (if choice 
                              (+ (get yes-votes proposal) voter-power)
                              (get yes-votes proposal)),
                  no-votes: (if choice
                             (get no-votes proposal)
                             (+ (get no-votes proposal) voter-power)),
                  total-vote-weight: (+ (get total-vote-weight proposal) voter-power)
                })
              )
              
              (print { 
                event: "vote-cast", 
                proposal-id: id, 
                voter: tx-sender, 
                choice: choice,
                weight: voter-power 
              })
              (ok true)
            )
          )
        )
      (err ERR-NOT-FOUND)
    )
  )
)

;; ------------------------------------------------------------
;; Cancel Proposal (proposer only)
;; ------------------------------------------------------------

(define-public (cancel-proposal (id uint))
  (match (map-get? proposals id)
    proposal
      (begin
        (asserts! (is-eq tx-sender (get proposer proposal)) (err ERR-NOT-AUTHORIZED))
        (asserts! (<= block-height (get end-block proposal)) (err ERR-NOT-ENDED))
        (asserts! (not (get executed proposal)) (err ERR-ALREADY-EXECUTED))
        
        (map-set proposals id (merge proposal { canceled: true }))
        (print { event: "proposal-canceled", id: id })
        (ok true)
      )
    (err ERR-NOT-FOUND)
  )
)

;; ------------------------------------------------------------
;; Execute Proposal with Time-lock
;; ------------------------------------------------------------

(define-public (queue-execution (id uint))
  (match (map-get? proposals id)
    proposal
      (begin
        ;; Verify proposal can be executed
        (asserts! (> block-height (get end-block proposal)) (err ERR-PROPOSAL-ACTIVE))
        (asserts! (not (get executed proposal)) (err ERR-ALREADY-EXECUTED))
        (asserts! (not (get canceled proposal)) (err ERR-FAILED))
        (asserts! (> (get yes-votes proposal) (get no-votes proposal)) (err ERR-FAILED))
        (asserts! (>= (get total-vote-weight proposal) MIN-QUORUM) (err ERR-QUORUM-NOT-MET))
        
        ;; Set time-lock
        (let ((execution-time (+ block-height (get execution-delay proposal))))
          (map-set execution-timelock id execution-time)
          (print { 
            event: "execution-queued", 
            id: id, 
            execution-block: execution-time 
          })
          (ok execution-time)
        )
      )
    (err ERR-NOT-FOUND)
  )
)

(define-public (execute-proposal (id uint))
  (match (map-get? proposals id)
    proposal
      (begin
        ;; Check time-lock
        (match (map-get? execution-timelock id)
          timelock-block
            (begin
              (asserts! (>= block-height timelock-block) (err ERR-NOT-ENDED))
              (asserts! (not (get executed proposal)) (err ERR-ALREADY-EXECUTED))
              
              ;; Mark as executed
              (map-set proposals id (merge proposal { executed: true }))
              
              (print { event: "proposal-executed", id: id })
              (ok { 
                executed: true, 
                proposer: (get proposer proposal),
                final-yes: (get yes-votes proposal),
                final-no: (get no-votes proposal)
              })
            )
          (err ERR-NOT-FOUND)
        )
      )
    (err ERR-NOT-FOUND)
  )
)

;; ------------------------------------------------------------
;; Result with Enhanced Stats
;; ------------------------------------------------------------

(define-read-only (result (id uint))
  (match (map-get? proposals id)
    proposal
      (let 
        (
          (yes (get yes-votes proposal))
          (no (get no-votes proposal))
          (total (get total-vote-weight proposal))
          (approval (calculate-approval-rate yes no))
        )
        (ok { 
          passed: (and 
                    (> yes no)
                    (>= total MIN-QUORUM)
                    (>= approval MIN-APPROVAL-PERCENT)),
          yes-votes: yes,
          no-votes: no,
          total-weight: total,
          approval-rate: approval,
          quorum-met: (>= total MIN-QUORUM)
        })
      )
    (err ERR-NOT-FOUND)
  )
)
