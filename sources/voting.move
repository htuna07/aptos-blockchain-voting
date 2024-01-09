module module_address::voting_v2 {
    
    use std::signer;

    // Errors
    const EALREADY_REGISTERED: u64 = 1;
    const EALREADY_VOTED: u64 = 2;
    const ECANDIDATE_NOT_FOUND: u64 = 3;
    const EVOTING_ITSELF: u64 = 4;

    struct Vote has key {
        candidate: address 
    }

    struct Candidate has key {
        votes_count: u64
    }

    public entry fun register(account: &signer){
        // check if account has already registered
        assert!(!exists<Candidate>(signer::address_of(account)), EALREADY_REGISTERED);

        // initialite the candidate
        move_to(account, Candidate {
            votes_count: 0
        });
    }

    public entry fun vote(account: &signer, candidate_address: address) acquires Candidate {
        let signer_address = signer::address_of(account);

        // check if account has already voted
        assert!(!exists<Vote>(signer_address), EALREADY_VOTED);

        // check if candidate does exist
        assert!(exists<Candidate>(candidate_address), ECANDIDATE_NOT_FOUND);

        // check if voting itself
        assert!(signer_address != candidate_address, EVOTING_ITSELF);

        // set the vote of the signer
        move_to(account, Vote {
            candidate: candidate_address
        });

        // increase vote count of the candidate
        let votes_count = &mut borrow_global_mut<Candidate>(candidate_address).votes_count;
        *votes_count = *votes_count + 1

    }

    #[view]
    public fun get_vote_count(candidate_address: address): u64 acquires Candidate{
        if(!exists<Candidate>(candidate_address)) return 0;
        return borrow_global<Candidate>(candidate_address).votes_count
    } 

    #[test(admin = @0x123)]
    public entry fun test_register(admin: &signer) acquires Candidate {
        register(admin);

        let admin_address = signer::address_of(admin);
        let votes_count = borrow_global<Candidate>(admin_address).votes_count;
        
        assert!(votes_count == 0,4);
    }

    #[test(admin = @0x123, candidate1 = @0x321)]
    public entry fun test_vote(admin: &signer,candidate1: &signer) acquires Candidate,Vote {
        register(candidate1);
        
        let admin_address = signer::address_of(admin);
        let candidate1_address = signer::address_of(candidate1);

        vote(admin,candidate1_address);

        let admin_vote = borrow_global<Vote>(admin_address);
        assert!(admin_vote.candidate == candidate1_address, 3);

        let candidate1_votes_count = borrow_global<Candidate>(candidate1_address).votes_count;
        
        assert!(candidate1_votes_count == 1, 4);

        // be sure admin is not candidate and candidate1 vote is not created
        assert!(!exists<Candidate>(admin_address), 6);
        assert!(!exists<Vote>(candidate1_address), 7);
    }   

    #[test(admin = @0x123, candidate1 = @0x321)]
    public fun test_get_vote_count(admin: &signer,candidate1: &signer) acquires Candidate {
        let admin_address = signer::address_of(admin);
        assert!(get_vote_count(admin_address) == 0, 1);

        let candidate1_address = signer::address_of(candidate1);
        register(candidate1);
        assert!(get_vote_count(candidate1_address) == 0, 2);

        vote(admin,candidate1_address);
        assert!(get_vote_count(candidate1_address) == 1, 3);
    } 

    #[test(admin = @0x123)]
    #[expected_failure(abort_code = EALREADY_REGISTERED)]
    public entry fun test_register_twice(admin: &signer) {
        register(admin);
        register(admin);
    }

    #[test(admin = @0x123, not_candidate = @0x321)]
    #[expected_failure(abort_code = ECANDIDATE_NOT_FOUND)]
    public entry fun test_vote_to_not_candidate(admin: &signer,not_candidate: &signer) acquires Candidate {
        vote(admin,signer::address_of(not_candidate));
    }

    #[test(admin = @0x123, candidate1 = @0x321, candidate2 = @0x333)]
    #[expected_failure(abort_code = EALREADY_VOTED)]
    public entry fun test_vote_twice(admin: &signer,candidate1: &signer, candidate2: &signer) acquires Candidate {
        register(candidate1);
        register(candidate2);
        
        let candidate1_address = signer::address_of(candidate1);
        let candidate2_address = signer::address_of(candidate2);

        vote(admin,candidate1_address);
        vote(admin,candidate2_address);
    }  

    #[test(admin = @0x123)]
    #[expected_failure(abort_code = EVOTING_ITSELF)]
    public entry fun test_vote_itself(admin: &signer) acquires Candidate {
        register(admin);
        vote(admin,signer::address_of(admin));
    }   

}