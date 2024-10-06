module MyModule::CrowdFunding {
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use std::vector;
    use std::signer;
    
    struct Campaign has copy, drop, store {
        owner: address,
        title: vector<u8>,
        description: vector<u8>,
        target: u64,
        deadline: u64,
        amount_collected: u64,
        image: vector<u8>,
        donators: vector<address>,
        donations: vector<u64>,
    }

    struct CrowdFundingPlatform has key {
        campaigns: vector<Campaign>,
    }

    public entry fun initialize_platform(account: &signer) {
        move_to(account, CrowdFundingPlatform { campaigns: vector::empty<Campaign>() });
    }

    public entry fun create_campaign(
        account: &signer,
        title: vector<u8>,
        description: vector<u8>,
        target: u64,
        deadline: u64,
        image: vector<u8>,
    ) acquires CrowdFundingPlatform {
        assert!(timestamp::now_seconds() < deadline, 0);
        let account_addr = signer::address_of(account);
        let platform = borrow_global_mut<CrowdFundingPlatform>(account_addr);
        
        let new_campaign = Campaign {
            owner: account_addr,
            title,
            description,
            target,
            deadline,
            amount_collected: 0,
            image,
            donators: vector::empty<address>(),
            donations: vector::empty<u64>(),
        };
        vector::push_back(&mut platform.campaigns, new_campaign);
    }

    public entry fun donate_to_campaign(
        account: &signer,
        campaign_id: u64,
        amount: u64
    ) acquires CrowdFundingPlatform {
        let account_addr = signer::address_of(account);
        let platform = borrow_global_mut<CrowdFundingPlatform>(account_addr);
        let campaign_ref = vector::borrow_mut(&mut platform.campaigns, campaign_id);
        
        assert!(timestamp::now_seconds() < campaign_ref.deadline, 1);
        assert!(amount > 0, 2);
        
        vector::push_back(&mut campaign_ref.donators, account_addr);
        vector::push_back(&mut campaign_ref.donations, amount);
        campaign_ref.amount_collected = campaign_ref.amount_collected + amount;
    }

    #[view]
    public fun get_campaigns(account_addr: address): vector<Campaign> acquires CrowdFundingPlatform {
        let platform = borrow_global<CrowdFundingPlatform>(account_addr);
        platform.campaigns
    }

    #[view]
    public fun get_donators(
        account_addr: address,
        campaign_id: u64
    ): (vector<address>, vector<u64>) acquires CrowdFundingPlatform {
        let platform = borrow_global<CrowdFundingPlatform>(account_addr);
        let campaign_ref = vector::borrow(&platform.campaigns, campaign_id);
        (campaign_ref.donators, campaign_ref.donations)
    }

    fun disburse_funds(campaign_ref: &mut Campaign) {
        if (timestamp::now_seconds() >= campaign_ref.deadline && 
            campaign_ref.amount_collected >= campaign_ref.target) {
            // Logic for transferring funds would go here
            let num_donators = vector::length(&campaign_ref.donators);
            let num_donations = vector::length(&campaign_ref.donations);
            
            // Ensure there are donators before attempting to remove
            if (num_donators > 0) {
                vector::remove(&mut campaign_ref.donators, num_donators - 1);
            };
            
            // Ensure there are donations before attempting to remove
            if (num_donations > 0) {
                vector::remove(&mut campaign_ref.donations, num_donations - 1);
            }
        }
    }
}