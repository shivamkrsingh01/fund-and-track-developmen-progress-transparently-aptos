module MyModule::ProductLaunch {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    use std::error;

    /// Error codes
    const E_PROJECT_NOT_FOUND: u64 = 1;
    const E_GOAL_NOT_REACHED: u64 = 2;
    const E_ALREADY_LAUNCHED: u64 = 3;
    const E_NOT_OWNER: u64 = 4;

    /// Struct representing a crowdfunded product launch
    struct ProductLaunch has store, key {
        total_funds: u64,        // Total tokens raised for the product
        goal: u64,               // Funding goal required for launch
        launch_deadline: u64,    // Timestamp deadline for launch
        is_launched: bool,       // Whether product has been launched
        owner: address,          // Product creator address
        product_name: vector<u8>, // Name of the product being launched
    }

    /// Function to back a product launch with funding
    public fun back_product(
        backer: &signer, 
        creator_address: address, 
        amount: u64
    ) acquires ProductLaunch {
        // Verify product launch exists
        assert!(exists<ProductLaunch>(creator_address), error::not_found(E_PROJECT_NOT_FOUND));
        
        let launch = borrow_global_mut<ProductLaunch>(creator_address);
        
        // Check if product is already launched
        assert!(!launch.is_launched, error::invalid_state(E_ALREADY_LAUNCHED));
        
        // Transfer backing funds from backer to creator
        let backing = coin::withdraw<AptosCoin>(backer, amount);
        coin::deposit<AptosCoin>(creator_address, backing);
        
        // Update total funds raised
        launch.total_funds = launch.total_funds + amount;
    }

    /// Function to launch the product (only when goal is reached)
    public fun launch_product(creator: &signer) acquires ProductLaunch {
        let creator_addr = signer::address_of(creator);
        
        // Verify product launch exists
        assert!(exists<ProductLaunch>(creator_addr), error::not_found(E_PROJECT_NOT_FOUND));
        
        let launch = borrow_global_mut<ProductLaunch>(creator_addr);
        
        // Verify caller is the creator
        assert!(launch.owner == creator_addr, error::permission_denied(E_NOT_OWNER));
        
        // Check if funding goal has been reached
        assert!(launch.total_funds >= launch.goal, error::invalid_state(E_GOAL_NOT_REACHED));
        
        // Check if still within launch deadline
        let current_time = timestamp::now_seconds();
        assert!(current_time <= launch.launch_deadline, error::invalid_state(E_GOAL_NOT_REACHED));
        
        // Launch the product
        launch.is_launched = true;
    }
}