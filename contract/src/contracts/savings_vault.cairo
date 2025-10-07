#[starknet::contract]
pub mod SavingsVault {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::token::erc20::{DefaultConfig, ERC20Component};
    use openzeppelin::upgrades::UpgradeableComponent;
    use porketoption_contract::interfaces::isavings_vault::ISavingsVault;
    use porketoption_contract::structs::save_structs::{GoalSave, GroupSave, LockSave};
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Pausable Mixin
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        usdc_token: IERC20Dispatcher,
        //user savings data
        flexi_balances: Map<ContractAddress, u256>,
        user_total_deposits: Map<ContractAddress, u256>,
        user_total_interest: Map<ContractAddress, u256>,
        user_savings_streak: Map<ContractAddress, u64>,
        user_last_deposit: Map<ContractAddress, u64>,
        //lock savings data
        lock_save_counter: u256,
        lock_saves: Map<u256, LockSave>,
        user_lock_saves: Map<(ContractAddress, u256), bool>,
        user_lock_count: Map<ContractAddress, u256>,
        //goal savings data
        goal_save_counter: u256,
        goal_saves: Map<u256, GoalSave>,
        user_goal_saves: Map<(ContractAddress, u256), bool>,
        user_goal_count: Map<ContractAddress, u256>,
        // Group savings data
        group_save_counter: u256,
        group_saves: Map<u256, GroupSave>,
        group_members: Map<(u256, ContractAddress), bool>,
        group_member_contributions: Map<(u256, ContractAddress), u256>,
        user_groups: Map<(ContractAddress, u256), bool>,
        // Interest rates (basis points - 10000 = 100%)
        flexi_save_rate: u256,
        lock_save_rates: Map<u64, u256>, // duration => rate
        goal_save_rate: u256,
        group_save_rate: u256,
        // Platform settings
        minimum_deposit: u256,
        withdrawal_fee: u256,
        platform_fee: u256,
        emergency_pause: bool,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        // Deposit events
        FlexiDeposit: FlexiDeposit,
        LockSaveCreated: LockSaveCreated,
        LockSaveAutoReleased: LockSaveAutoReleased,
        GoalSaveCreated: GoalSaveCreated,
        GoalContribution: GoalContribution,
        GoalCompleted: GoalCompleted,
        GoalSaveBroken: GoalSaveBroken,
        GoalSaveWithdrawn: GoalSaveWithdrawn,
        GroupSaveCreated: GroupSaveCreated,
        GroupJoined: GroupJoined,
        GroupContribution: GroupContribution,
        GroupSaveBroken: GroupSaveBroken,
        // Withdrawal events
        Withdrawal: Withdrawal,
        // Interest events
        InterestAccrued: InterestAccrued,
        InterestPaid: InterestPaid,
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    pub struct FlexiDeposit {
        pub user: ContractAddress,
        pub amount: u256,
        pub timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct LockSaveCreated {
        pub id: u256,
        pub user: ContractAddress,
        pub amount: u256,
        pub duration: u64,
        pub interest_rate: u256,
        pub maturity_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct LockSaveAutoReleased {
        pub id: u256,
        pub user: ContractAddress,
        pub principal: u256,
        pub interest: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GoalSaveCreated {
        pub id: u256,
        pub user: ContractAddress,
        pub title: felt252,
        pub target_amount: u256,
        pub start_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GoalContribution {
        pub id: u256,
        pub user: ContractAddress,
        pub amount: u256,
        pub current_total: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GoalCompleted {
        pub id: u256,
        pub user: ContractAddress,
        pub final_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GoalSaveBroken {
        pub id: u256,
        pub user: ContractAddress,
        pub refunded_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GoalSaveWithdrawn {
        pub id: u256,
        pub user: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GroupSaveCreated {
        pub id: u256,
        pub creator: ContractAddress,
        pub title: felt252,
        pub target_amount: u256,
        pub is_public: bool,
        pub start_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GroupJoined {
        pub group_id: u256,
        pub user: ContractAddress,
        pub member_count: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GroupContribution {
        pub group_id: u256,
        pub user: ContractAddress,
        pub amount: u256,
        pub group_total: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct GroupSaveBroken {
        pub group_id: u256,
        pub creator: ContractAddress,
        pub refunded_amounts: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Withdrawal {
        pub user: ContractAddress,
        pub amount: u256,
        pub fee: u256,
        pub timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct InterestAccrued {
        pub user: ContractAddress,
        pub amount: u256,
        pub save_type: felt252 // 'flexi', 'goal', 'group'
    }

    #[derive(Drop, starknet::Event)]
    pub struct InterestPaid {
        pub user: ContractAddress,
        pub amount: u256,
        pub save_type: felt252,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        usdc_token: ContractAddress,
        flexi_rate: u256,
        goal_rate: u256,
        group_rate: u256,
    ) {
        self.usdc_token.write(IERC20Dispatcher { contract_address: usdc_token });
        self.ownable.initializer(owner);
        self.flexi_save_rate.write(flexi_rate);
        self.goal_save_rate.write(goal_rate);
        self.group_save_rate.write(group_rate);
        self.minimum_deposit.write(1000000); // 1 USDC (6 decimals)
        self.withdrawal_fee.write(50); // 0.5% in basis points
        self.platform_fee.write(100); // 1% in basis points

        // Initialize lock save rates (basis points)
        self.lock_save_rates.entry(30).write(400); // 10-30 days: 4%
        self.lock_save_rates.entry(60).write(600); // 31-60 days: 6%
        self.lock_save_rates.entry(90).write(800); // 61-90 days: 8%
        self.lock_save_rates.entry(180).write(1000); // 91-180 days: 10%
        self.lock_save_rates.entry(270).write(1200); // 181-270 days: 12%
        self.lock_save_rates.entry(365).write(1500); // 271-365 days: 15%
    }

    #[abi(embed_v0)]
    pub impl SavingsVaultImpl of ISavingsVault<ContractState> {
        fn flexi_deposit(ref self: ContractState, amount: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            assert(amount >= self.minimum_deposit.read(), 'Amount too low');

            let usdc = self.usdc_token.read();
            usdc.transfer_from(caller, get_contract_address(), amount);

            let caller_balance = self.flexi_balances.entry(caller).read();
            self.flexi_balances.entry(caller).write(caller_balance + amount);

            let total_deposits = self.user_total_deposits.entry(caller).read();
            self.user_total_deposits.entry(caller).write(total_deposits + amount);

            self._update_savings_streak(caller);

            self.emit(FlexiDeposit { user: caller, amount, timestamp: get_block_timestamp() });
        }

        fn flexi_withdraw(ref self: ContractState, amount: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            let balance = self.flexi_balances.entry(caller).read();
            assert(amount <= balance, 'Insufficient balance');

            // Calculate withdrawal fee
            let fee = (amount * self.withdrawal_fee.read()) / 10000;
            let net_amount = amount - fee;
            let usdc = self.usdc_token.read();

            // Update balances
            self.flexi_balances.entry(caller).write(balance - amount);
            self
                .user_total_deposits
                .entry(caller)
                .write(self.user_total_deposits.entry(caller).read() - amount);

            // Transfer to user
            usdc.transfer(caller, net_amount);
            // Transfer fee to platform
            usdc.transfer(self.ownable.owner(), fee);

            self
                .emit(
                    Withdrawal {
                        user: caller, amount: net_amount, fee, timestamp: get_block_timestamp(),
                    },
                );

            // Distribute interest if applicable
            self._distribute_flexi_interest(caller);
        }

        fn create_lock_save(
            ref self: ContractState, amount: u256, duration: u64, title: felt252,
        ) -> u256 {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            assert(amount >= self.minimum_deposit.read(), 'Amount too low');
            assert(duration >= 10 && duration <= 365, 'Invalid duration');

            let interest_rate = self._get_lock_save_rate(duration);
            let usdc = self.usdc_token.read();

            usdc.transfer_from(caller, get_contract_address(), amount);

            // Update user's total deposits
            let total_deposits = self.user_total_deposits.entry(caller).read();
            self.user_total_deposits.entry(caller).write(total_deposits + amount);

            let id = self.lock_save_counter.read() + 1;
            self.lock_save_counter.write(id);

            let current_time = get_block_timestamp();
            let maturity_time = current_time + (duration * 86400);

            let lock_save = LockSave {
                id,
                user: caller,
                amount,
                interest_rate,
                lock_duration: duration,
                start_time: current_time,
                maturity_time,
                title,
                is_matured: false,
                is_withdrawn: false,
            };

            self.lock_saves.entry(id).write(lock_save);
            self.user_lock_saves.entry((caller, id)).write(true);

            let user_lock_count = self.user_lock_count.entry(caller).read();
            self.user_lock_count.entry(caller).write(user_lock_count + 1);

            self._update_savings_streak(caller);

            self
                .emit(
                    LockSaveCreated {
                        id, user: caller, amount, duration, interest_rate, maturity_time,
                    },
                );

            id
        }

        // Auto-release function - should be called periodically or when checking lock saves
        fn auto_release_matured_lock_saves(ref self: ContractState, user: ContractAddress) {
            let current_time = get_block_timestamp();
            let usdc = self.usdc_token.read();

            let mut i = 1;
            loop {
                if i > self.lock_save_counter.read() {
                    break;
                }

                let lock_save_check = self.lock_saves.entry(i).read();
                if lock_save_check.user == user
                    && !lock_save_check.is_matured
                    && !lock_save_check.is_withdrawn
                    && current_time >= lock_save_check.maturity_time {
                    let mut lock_save = self.lock_saves.entry(i).read();
                    let principal = lock_save.amount;
                    let interest = self
                        ._calculate_lock_interest(
                            principal, lock_save.interest_rate, lock_save.lock_duration,
                        );
                    let total_amount = principal + interest;

                    // Transfer directly to user's wallet
                    usdc.transfer(user, total_amount);

                    // Update user's total deposits (reduce by principal)
                    let current_deposits = self.user_total_deposits.entry(user).read();
                    self.user_total_deposits.entry(user).write(current_deposits - principal);

                    // Update interest tracking
                    let user_interest = self.user_total_interest.entry(user).read();
                    self.user_total_interest.entry(user).write(user_interest + interest);

                    // Mark as matured and withdrawn
                    lock_save.is_matured = true;
                    lock_save.is_withdrawn = true;
                    self.lock_saves.entry(i).write(lock_save);

                    self.emit(LockSaveAutoReleased { id: i, user, principal, interest });
                }

                i += 1;
            };
        }

        fn create_goal_save(
            ref self: ContractState,
            title: felt252,
            category: felt252,
            target_amount: u256,
            contribution_type: u8,
            contribution_amount: u256,
            start_time: u64, // User-defined start time
            end_time: u64,
        ) -> u256 {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            assert(target_amount > 0, 'Target amount less than 0');
            assert(contribution_type >= 1 && contribution_type <= 4, 'Invalid contribution type');
            assert(end_time > start_time, 'End time after start time');
            assert(start_time >= get_block_timestamp(), 'Start time must be in future');

            let id = self.goal_save_counter.read() + 1;
            self.goal_save_counter.write(id);

            let goal_save = GoalSave {
                id,
                user: caller,
                title,
                category,
                target_amount,
                current_amount: 0,
                contribution_type,
                contribution_amount,
                start_time,
                end_time,
                is_completed: false,
            };

            self.goal_saves.entry(id).write(goal_save);
            self.user_goal_saves.entry((caller, id)).write(true);
            let user_goal_count = self.user_goal_count.entry(caller).read();
            self.user_goal_count.entry(caller).write(user_goal_count + 1);

            self.emit(GoalSaveCreated { id, user: caller, title, target_amount, start_time });

            id
        }

        fn contribute_goal_save(ref self: ContractState, goal_id: u256, amount: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            let mut goal_save = self.goal_saves.entry(goal_id).read();
            assert(goal_save.user == caller, 'Not owner of goal save');
            assert(!goal_save.is_completed, 'Goal already completed');
            assert(amount >= self.minimum_deposit.read(), 'Amount too low');

            let current_time = get_block_timestamp();
            assert(current_time >= goal_save.start_time, 'Goal not started yet');
            assert(current_time <= goal_save.end_time, 'Goal period ended');

            let usdc = self.usdc_token.read();
            usdc.transfer_from(caller, get_contract_address(), amount);

            goal_save.current_amount += amount;

            if goal_save.current_amount >= goal_save.target_amount {
                goal_save.is_completed = true;
                self
                    .emit(
                        GoalCompleted {
                            id: goal_id, user: caller, final_amount: goal_save.current_amount,
                        },
                    );
            }

            self.goal_saves.entry(goal_id).write(goal_save);

            let total_deposits = self.user_total_deposits.entry(caller).read();
            self.user_total_deposits.entry(caller).write(total_deposits + amount);

            self._update_savings_streak(caller);

            self
                .emit(
                    GoalContribution {
                        id: goal_id, user: caller, amount, current_total: goal_save.current_amount,
                    },
                );
        }

        fn break_goal_save(ref self: ContractState, goal_id: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            let mut goal_save = self.goal_saves.entry(goal_id).read();
            assert(goal_save.user == caller, 'Not owner of goal save');
            assert(!goal_save.is_completed, 'Goal already completed');
            assert(goal_save.current_amount > 0, 'No funds to refund');

            let refund_amount = goal_save.current_amount;
            let usdc = self.usdc_token.read();

            // Calculate penalty fee (e.g., 2% of saved amount)
            let penalty_fee = (refund_amount * 200) / 10000; // 2%
            let net_refund = refund_amount - penalty_fee;

            // Add refund to flexi balance
            let current_flexi = self.flexi_balances.entry(caller).read();
            self.flexi_balances.entry(caller).write(current_flexi + net_refund);

            // Transfer penalty to platform
            usdc.transfer(self.ownable.owner(), penalty_fee);

            // Mark goal as completed (broken)
            goal_save.is_completed = true;
            goal_save.current_amount = 0;
            self.goal_saves.entry(goal_id).write(goal_save);

            self.emit(GoalSaveBroken { id: goal_id, user: caller, refunded_amount: net_refund });
        }

        fn withdraw_completed_goal_save(ref self: ContractState, goal_id: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            let goal_save = self.goal_saves.entry(goal_id).read();
            assert(goal_save.user == caller, 'Not owner of goal save');
            assert(goal_save.is_completed, 'Goal not completed');
            assert(goal_save.current_amount > 0, 'No funds to withdraw');

            let withdrawal_amount = goal_save.current_amount;
            let usdc = self.usdc_token.read();

            // Calculate interest
            let interest = self._calculate_goal_interest(withdrawal_amount);
            let total_amount = withdrawal_amount + interest;

            // Transfer to user
            usdc.transfer(caller, total_amount);

            // Update goal save
            let mut updated_goal = goal_save;
            updated_goal.current_amount = 0;
            self.goal_saves.entry(goal_id).write(updated_goal);

            self.emit(GoalSaveWithdrawn { id: goal_id, user: caller, amount: total_amount });
        }

        fn create_group_save(
            ref self: ContractState,
            title: felt252,
            description: felt252,
            category: felt252,
            target_amount: u256,
            contribution_type: u8,
            contribution_amount: u256,
            is_public: bool,
            start_time: u64, // User-defined start time
            end_time: u64,
        ) -> u256 {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            assert(target_amount >= self.minimum_deposit.read(), 'Target too small');
            assert(contribution_type >= 1 && contribution_type <= 4, 'Invalid contribution type');
            assert(end_time > start_time, 'End time after start time');
            assert(start_time >= get_block_timestamp(), 'Start time must be in future');

            let id = self.group_save_counter.read() + 1;
            self.group_save_counter.write(id);

            let group_save = GroupSave {
                id,
                creator: caller,
                title,
                description,
                category,
                target_amount,
                current_amount: 0,
                contribution_type,
                contribution_amount,
                is_public,
                member_count: 1,
                start_time,
                end_time,
                is_completed: false,
            };

            self.group_saves.entry(id).write(group_save);
            self.user_groups.entry((caller, id)).write(true);
            self.group_members.entry((id, caller)).write(true);

            self
                .emit(
                    GroupSaveCreated {
                        id, creator: caller, title, target_amount, is_public, start_time,
                    },
                );
            id
        }

        fn join_group_save(ref self: ContractState, group_id: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            let mut group_save = self.group_saves.entry(group_id).read();
            assert(!group_save.is_completed, 'Group already completed');
            assert(!self.group_members.entry((group_id, caller)).read(), 'Already a member');

            let current_time = get_block_timestamp();
            assert(current_time >= group_save.start_time, 'Group not started yet');
            assert(current_time <= group_save.end_time, 'Group period ended');

            // Add member to group
            self.group_members.entry((group_id, caller)).write(true);
            self.user_groups.entry((caller, group_id)).write(true);

            group_save.member_count += 1;
            self.group_saves.entry(group_id).write(group_save);

            self
                .emit(
                    GroupJoined { group_id, user: caller, member_count: group_save.member_count },
                );
        }

        fn contribute_to_group_save(ref self: ContractState, group_id: u256, amount: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            let mut group_save = self.group_saves.entry(group_id).read();
            assert(!group_save.is_completed, 'Group already completed');
            assert(self.group_members.entry((group_id, caller)).read(), 'Not a member');
            assert(amount >= self.minimum_deposit.read(), 'Amount too small');

            let current_time = get_block_timestamp();
            assert(current_time >= group_save.start_time, 'Group not started yet');
            assert(current_time <= group_save.end_time, 'Group period ended');

            let usdc = self.usdc_token.read();
            usdc.transfer_from(caller, get_contract_address(), amount);

            // Update group progress
            group_save.current_amount += amount;

            // Update member contribution
            let current_contribution = self
                .group_member_contributions
                .entry((group_id, caller))
                .read();
            self
                .group_member_contributions
                .entry((group_id, caller))
                .write(current_contribution + amount);

            // Check if group goal is completed
            if group_save.current_amount >= group_save.target_amount {
                group_save.is_completed = true;
            }

            self.group_saves.entry(group_id).write(group_save);

            // Update user stats
            let total_deposits = self.user_total_deposits.entry(caller).read();
            self.user_total_deposits.entry(caller).write(total_deposits + amount);

            self._update_savings_streak(caller);

            self
                .emit(
                    GroupContribution {
                        group_id, user: caller, amount, group_total: group_save.current_amount,
                    },
                );
        }

        fn break_group_save(ref self: ContractState, group_id: u256) {
            self.pausable.assert_not_paused();
            let caller = get_caller_address();

            let mut group_save = self.group_saves.entry(group_id).read();
            assert(group_save.creator == caller, 'Not the creator');
            assert(!group_save.is_completed, 'Group already completed');
            assert(group_save.current_amount > 0, 'No funds to refund');

            // Refund all members their contributions
            let total_refund = group_save.current_amount;
            let usdc = self.usdc_token.read();

            // Calculate penalty fee (e.g., 3% of total saved amount)
            let penalty_fee = (total_refund * 300) / 10000; // 3%
            let net_refund = total_refund - penalty_fee;

            // Mark group as completed (broken)
            group_save.is_completed = true;
            group_save.current_amount = 0;
            self.group_saves.entry(group_id).write(group_save);

            // Transfer penalty to platform
            usdc.transfer(self.ownable.owner(), penalty_fee);

            // Refund net amount to creator (simplified - in production, would distribute to all members)
            // TODO: Implement proper member contribution tracking for proportional refunds
            usdc.transfer(caller, net_refund);

            self.emit(GroupSaveBroken { group_id, creator: caller, refunded_amounts: net_refund });
        }

        // READ FUNCTIONS FOR FRONTEND

        fn get_flexi_balance(self: @ContractState, user: ContractAddress) -> u256 {
            self.flexi_balances.entry(user).read()
        }

        fn get_user_ongoing_lock_saves(
            self: @ContractState, user: ContractAddress,
        ) -> Array<LockSave> {
            let mut ongoing_locks = ArrayTrait::new();
            let current_time = get_block_timestamp();

            let mut i = 1;
            loop {
                if i > self.lock_save_counter.read() {
                    break;
                }

                let lock_save = self.lock_saves.entry(i).read();
                if lock_save.user == user
                    && !lock_save.is_matured
                    && !lock_save.is_withdrawn
                    && current_time < lock_save.maturity_time {
                    ongoing_locks.append(lock_save);
                }

                i += 1;
            }

            ongoing_locks
        }

        fn get_user_matured_lock_saves(
            self: @ContractState, user: ContractAddress,
        ) -> Array<LockSave> {
            let mut matured_locks = ArrayTrait::new();

            let mut i = 1;
            loop {
                if i > self.lock_save_counter.read() {
                    break;
                }

                let lock_save = self.lock_saves.entry(i).read();
                if lock_save.user == user && lock_save.is_matured && lock_save.is_withdrawn {
                    matured_locks.append(lock_save);
                }

                i += 1;
            }

            matured_locks
        }

        fn get_user_live_goal_saves(
            self: @ContractState, user: ContractAddress,
        ) -> Array<GoalSave> {
            let mut live_goals = ArrayTrait::new();

            let mut i = 1;
            loop {
                if i > self.goal_save_counter.read() {
                    break;
                }

                let goal_save = self.goal_saves.entry(i).read();
                if goal_save.user == user && !goal_save.is_completed {
                    live_goals.append(goal_save);
                }

                i += 1;
            }

            live_goals
        }

        fn get_user_completed_goal_saves(
            self: @ContractState, user: ContractAddress,
        ) -> Array<GoalSave> {
            let mut completed_goals = ArrayTrait::new();

            let mut i = 1;
            loop {
                if i > self.goal_save_counter.read() {
                    break;
                }

                let goal_save = self.goal_saves.entry(i).read();
                if goal_save.user == user && goal_save.is_completed {
                    completed_goals.append(goal_save);
                }

                i += 1;
            }

            completed_goals
        }

        fn get_user_live_group_saves(
            self: @ContractState, user: ContractAddress,
        ) -> Array<GroupSave> {
            let mut live_groups = ArrayTrait::new();

            let mut i = 1;
            loop {
                if i > self.group_save_counter.read() {
                    break;
                }

                let group_save = self.group_saves.entry(i).read();
                if self.group_members.entry((i, user)).read() && !group_save.is_completed {
                    live_groups.append(group_save);
                }

                i += 1;
            }

            live_groups
        }

        fn get_user_completed_group_saves(
            self: @ContractState, user: ContractAddress,
        ) -> Array<GroupSave> {
            let mut completed_groups = ArrayTrait::new();

            let mut i = 1;
            loop {
                if i > self.group_save_counter.read() {
                    break;
                }

                let group_save = self.group_saves.entry(i).read();
                if self.group_members.entry((i, user)).read() && group_save.is_completed {
                    completed_groups.append(group_save);
                }

                i += 1;
            }

            completed_groups
        }

        fn get_user_lock_save_balance(self: @ContractState, user: ContractAddress) -> u256 {
            let mut total_locked = 0;
            let current_time = get_block_timestamp();

            let mut i = 1;
            loop {
                if i > self.lock_save_counter.read() {
                    break;
                }

                let lock_save = self.lock_saves.entry(i).read();
                if lock_save.user == user
                    && !lock_save.is_matured
                    && !lock_save.is_withdrawn
                    && current_time < lock_save.maturity_time {
                    total_locked += lock_save.amount;
                }

                i += 1;
            }

            total_locked
        }

        fn get_user_goal_save_balance(self: @ContractState, user: ContractAddress) -> u256 {
            let mut total_goal_balance = 0;

            let mut i = 1;
            loop {
                if i > self.goal_save_counter.read() {
                    break;
                }

                let goal_save = self.goal_saves.entry(i).read();
                if goal_save.user == user && !goal_save.is_completed {
                    total_goal_balance += goal_save.current_amount;
                }

                i += 1;
            }

            total_goal_balance
        }

        fn get_user_group_save_balance(self: @ContractState, user: ContractAddress) -> u256 {
            let mut total_group_balance = 0;

            let mut i = 1;
            loop {
                if i > self.group_save_counter.read() {
                    break;
                }

                if self.group_members.entry((i, user)).read() {
                    total_group_balance += self.group_member_contributions.entry((i, user)).read();
                }

                i += 1;
            }

            total_group_balance
        }

        // Original getter functions
        fn get_lock_save(self: @ContractState, lock_id: u256) -> LockSave {
            self.lock_saves.entry(lock_id).read()
        }

        fn get_goal_save(self: @ContractState, goal_id: u256) -> GoalSave {
            self.goal_saves.entry(goal_id).read()
        }

        fn get_group_save(self: @ContractState, group_id: u256) -> GroupSave {
            self.group_saves.entry(group_id).read()
        }

        fn get_user_total_deposits(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_total_deposits.entry(user).read()
        }

        fn get_user_total_interest(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_total_interest.entry(user).read()
        }

        fn get_user_savings_streak(self: @ContractState, user: ContractAddress) -> u64 {
            self.user_savings_streak.entry(user).read()
        }

        fn get_lock_save_rate(self: @ContractState, duration_days: u64) -> u256 {
            self._get_lock_save_rate(duration_days)
        }

        fn get_flexi_save_rate(self: @ContractState) -> u256 {
            self.flexi_save_rate.read()
        }

        fn get_goal_save_rate(self: @ContractState) -> u256 {
            self.goal_save_rate.read()
        }

        fn get_group_save_rate(self: @ContractState) -> u256 {
            self.group_save_rate.read()
        }

        fn is_group_member(self: @ContractState, group_id: u256, user: ContractAddress) -> bool {
            self.group_members.entry((group_id, user)).read()
        }

        fn get_group_member_contribution(
            self: @ContractState, group_id: u256, user: ContractAddress,
        ) -> u256 {
            self.group_member_contributions.entry((group_id, user)).read()
        }

        fn calculate_lock_save_maturity(self: @ContractState, lock_id: u256) -> (u256, u256) {
            let lock_save = self.lock_saves.entry(lock_id).read();
            let interest = self
                ._calculate_lock_interest(
                    lock_save.amount, lock_save.interest_rate, lock_save.lock_duration,
                );
            (lock_save.amount, interest)
        }

        // ADMIN FUNCTIONS
        fn set_interest_rates(
            ref self: ContractState, flexi_rate: u256, goal_rate: u256, group_rate: u256,
        ) {
            self.ownable.assert_only_owner();
            self.flexi_save_rate.write(flexi_rate);
            self.goal_save_rate.write(goal_rate);
            self.group_save_rate.write(group_rate);
        }

        fn set_lock_save_rate(ref self: ContractState, duration_days: u64, rate: u256) {
            self.ownable.assert_only_owner();
            self.lock_save_rates.entry(duration_days).write(rate);
        }

        fn set_platform_settings(
            ref self: ContractState,
            minimum_deposit: u256,
            withdrawal_fee: u256,
            platform_fee: u256,
        ) {
            self.ownable.assert_only_owner();
            self.minimum_deposit.write(minimum_deposit);
            self.withdrawal_fee.write(withdrawal_fee);
            self.platform_fee.write(platform_fee);
        }

        fn emergency_pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        }

        fn emergency_unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
        }

        fn emergency_withdraw(ref self: ContractState, amount: u256) {
            self.ownable.assert_only_owner();
            let usdc = self.usdc_token.read();
            usdc.transfer(self.ownable.owner(), amount);
        }
    }

    impl ERC20HooksImpl of ERC20Component::ERC20HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {
            let contract_state = self.get_contract();
            contract_state.pausable.assert_not_paused();
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalImplTrait {
        fn _get_lock_save_rate(self: @ContractState, duration_days: u64) -> u256 {
            if duration_days <= 30 {
                self.lock_save_rates.entry(30).read()
            } else if duration_days <= 60 {
                self.lock_save_rates.entry(60).read()
            } else if duration_days <= 90 {
                self.lock_save_rates.entry(90).read()
            } else if duration_days <= 180 {
                self.lock_save_rates.entry(180).read()
            } else if duration_days <= 270 {
                self.lock_save_rates.entry(270).read()
            } else {
                self.lock_save_rates.entry(365).read()
            }
        }

        fn _calculate_lock_interest(
            self: @ContractState, principal: u256, annual_rate: u256, duration_days: u64,
        ) -> u256 {
            // Rate is in basis points (10000 = 100%)
            (principal * annual_rate * duration_days.into()) / (10000 * 365)
        }

        fn _calculate_goal_interest(self: @ContractState, principal: u256) -> u256 {
            let annual_rate = self.goal_save_rate.read();
            // Simplified daily interest calculation
            (principal * annual_rate) / (10000 * 365)
        }

        fn _update_savings_streak(ref self: ContractState, user: ContractAddress) {
            let current_time = get_block_timestamp();
            let last_deposit = self.user_last_deposit.entry(user).read();

            // If last deposit was within 24 hours, don't update streak
            if current_time - last_deposit < 86400 {
                return;
            }

            // If last deposit was more than 48 hours ago, reset streak
            if last_deposit > 0 && current_time - last_deposit > 172800 {
                self.user_savings_streak.entry(user).write(1);
            } else {
                let current_streak = self.user_savings_streak.entry(user).read();
                self.user_savings_streak.entry(user).write(current_streak + 1);
            }

            self.user_last_deposit.entry(user).write(current_time);
        }

        fn _distribute_flexi_interest(ref self: ContractState, user: ContractAddress) {
            let balance = self.flexi_balances.entry(user).read();
            if balance == 0 {
                return;
            }

            let annual_rate = self.flexi_save_rate.read();
            // Calculate daily interest (simplified)
            let daily_interest = (balance * annual_rate) / (10000 * 365);

            self.flexi_balances.entry(user).write(balance + daily_interest);

            let user_interest = self.user_total_interest.entry(user).read();
            self.user_total_interest.entry(user).write(user_interest + daily_interest);

            self.emit(InterestAccrued { user, amount: daily_interest, save_type: 'flexi' });
        }
    }
}

