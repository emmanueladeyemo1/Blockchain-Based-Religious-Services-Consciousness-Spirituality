;; Practice Coordination Contract
;; Manages consciousness spiritual practices

(define-data-var admin principal tx-sender)

;; Map to store spiritual practices
(define-map spiritual-practices
  { practice-id: (string-ascii 64) }
  {
    name: (string-utf8 256),
    description: (string-utf8 1024),
    institution-id: (string-ascii 64),
    duration-minutes: uint,
    participants-required: uint,
    created-at: uint
  }
)

;; Map to store practice sessions
(define-map practice-sessions
  { session-id: (string-ascii 64) }
  {
    practice-id: (string-ascii 64),
    facilitator: principal,
    start-time: uint,
    max-participants: uint,
    current-participants: uint,
    status: (string-ascii 16)
  }
)

;; Map to track session participants
(define-map session-participants
  { session-id: (string-ascii 64), participant: principal }
  { joined-at: uint }
)

;; Public function to register a spiritual practice
(define-public (register-practice
    (practice-id (string-ascii 64))
    (name (string-utf8 256))
    (description (string-utf8 1024))
    (institution-id (string-ascii 64))
    (duration-minutes uint)
    (participants-required uint))
  (begin
    (map-set spiritual-practices
      { practice-id: practice-id }
      {
        name: name,
        description: description,
        institution-id: institution-id,
        duration-minutes: duration-minutes,
        participants-required: participants-required,
        created-at: block-height
      }
    )
    (ok true)
  )
)

;; Public function to schedule a practice session
(define-public (schedule-session
    (session-id (string-ascii 64))
    (practice-id (string-ascii 64))
    (start-time uint)
    (max-participants uint))
  (begin
    (asserts! (is-some (map-get? spiritual-practices { practice-id: practice-id })) (err u404))
    (map-set practice-sessions
      { session-id: session-id }
      {
        practice-id: practice-id,
        facilitator: tx-sender,
        start-time: start-time,
        max-participants: max-participants,
        current-participants: u1, ;; Facilitator counts as first participant
        status: "scheduled"
      }
    )
    (map-set session-participants
      { session-id: session-id, participant: tx-sender }
      { joined-at: block-height }
    )
    (ok true)
  )
)

;; Public function to join a practice session
(define-public (join-session (session-id (string-ascii 64)))
  (let (
    (session (unwrap! (map-get? practice-sessions { session-id: session-id }) (err u404)))
    (current-participants (get current-participants session))
    (max-participants (get max-participants session))
  )
    (asserts! (< current-participants max-participants) (err u409))
    (asserts! (is-eq (get status session) "scheduled") (err u403))
    (asserts! (is-none (map-get? session-participants { session-id: session-id, participant: tx-sender })) (err u409))

    (map-set practice-sessions
      { session-id: session-id }
      (merge session { current-participants: (+ current-participants u1) })
    )
    (map-set session-participants
      { session-id: session-id, participant: tx-sender }
      { joined-at: block-height }
    )
    (ok true)
  )
)

;; Read-only function to get practice details
(define-read-only (get-practice-details (practice-id (string-ascii 64)))
  (map-get? spiritual-practices { practice-id: practice-id })
)

;; Read-only function to get session details
(define-read-only (get-session-details (session-id (string-ascii 64)))
  (map-get? practice-sessions { session-id: session-id })
)

;; Read-only function to check if user is participant
(define-read-only (is-participant (session-id (string-ascii 64)) (user principal))
  (is-some (map-get? session-participants { session-id: session-id, participant: user }))
)
