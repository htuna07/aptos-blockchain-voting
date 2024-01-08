module module_address::voting {
    
    use aptos_std::table_with_length::{Self,TableWithLength};
    use std::string::String;
    use std::signer;

    #[test_only]
    use std::string;
    use aptos_framework::account;

    // Errors
    const EALREADY_REGISTERED: u64 = 1;
    const EALREADY_VOTED: u64 = 2;
    const ECANDIDATE_NOT_FOUND: u64 = 3;

    struct Voter has key {
        candidate: address 
    }

    struct Candidate has key {
        votes: TableWithLength<u64,Vote>
    }

    struct Vote has store {
        owner: address
    }

    public entry fun register(account: &signer){
        // check if account has already registered
        assert!(!exists<Candidate>(signer::address_of(account)), EALREADY_REGISTERED);

        // initialite the candidate
        move_to(account, Candidate {
            votes: table_with_length::new()
        });
    }

    public entry fun vote(account: &signer, candidate_address: address) acquires Candidate {
        let signer_address = signer::address_of(account);

        // check if account has already voted
        assert!(!exists<Voter>(signer_address), EALREADY_VOTED);

        // check if candidate does exist
        assert!(exists<Candidate>(candidate_address), ECANDIDATE_NOT_FOUND);

        // set the vote of the signer
        move_to(account, Voter {
            candidate: candidate_address
        });

        // add vote to the candidate
        let candidate = borrow_global_mut<Candidate>(candidate_address);

        let length = table_with_length::length(&mut candidate.votes);

        table_with_length::add(&mut candidate.votes, length + 1, Vote { owner: signer_address } );
    }

    #[test(admin = @0x123)]
    public entry fun test_register(admin: signer) {
        account::create_account_for_test(signer::address_of(&admin));

        register(&admin);
        // assert details
    }

    #[test(admin = @0x123)]
    #[expected_failure(abort_code = EALREADY_REGISTERED)]
    public entry fun test_register_twice(admin: signer) {
        account::create_account_for_test(signer::address_of(&admin));

        register(&admin);
        register(&admin);
    }

    #[test(admin = @0x123, not_candidate = @0x321)]
    #[expected_failure(abort_code = ECANDIDATE_NOT_FOUND)]
    public entry fun vote_to_unregistered_candidate(admin: &signer,not_candidate: &signer) acquires Candidate {
        vote(admin,signer::address_of(not_candidate));
    }

    #[test(admin = @0x123, candidate1 = @0x321, candidate2 = @0x333)]
    #[expected_failure(abort_code = EALREADY_VOTED)]
    public entry fun vote_twice(admin: &signer,candidate1: &signer, candidate2: &signer) acquires Candidate {
        register(candidate1);
        register(candidate2);
        
        let candidate1_address = signer::address_of(candidate1);
        let candidate2_address = signer::address_of(candidate2);

        vote(admin,candidate1_address);
        vote(admin,candidate2_address);
    }   

    // add tests for success scenarios
}