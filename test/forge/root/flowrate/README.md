# Test plan for RootERC20PreficateFlowRate and assocaited contracts

The following are unit tests for the flow rate control code.


## Flow Rate Detection
This section defines tests for contracts/root/flowrate/FlowRateDetection.sol

Uninitialized testing: Check that default values are returned by view calls:

| Test name                 | Description                                       | Happy Case | Implemented |
|---------------------------| --------------------------------------------------|------------|-------------|
| testUninitFlowRateBuckets | flowRateBuckets(address) returns an empty bucket. | NA         | Yes         |
|                           | withdrawalQueueActivated returns false.           | NA         | No          |



Control functions tests:

| Test name | Description | Happy Case | Implemented | 
|-----------|-------------|-------------|-----|
|          | _activateWithdrawalQueue() | Yes | No |
|            | _deactivateWithdrawalQueue() when withdrawalQueueActivate is true | Yes | No |
|           | _setFlowRateThreshold() with valid values | Yes | No |
|           | _setFlowRateThreshold() with token address = 0 | No | No |
|           | _setFlowRateThreshold() with capacity = 0 | No | No |
|           | _setFlowRateThreshold() with refill rate = 0 | No | No |

Operational functions tests:

| Test name | Description | Happy Case | Implemented | 
|-----------|-------------|-------------|-----|
|           | _updateFlowRateBucket() with a single call for a configured token | Yes | No |
|           | _updateFlowRateBucket() with a multiple calls for a configured token | Yes | No |
|           | _updateFlowRateBucket() with a two calls, after the bucket has been refilled | Yes | No |
|           | _updateFlowRateBucket() with one call to empty the bucket | Yes | No |
|           | _updateFlowRateBucket() unconfigured bucket | No | No |


## Flow Rate Withdrawal Queue
This section defines tests for contracts/root/flowrate/FlowRateWithdrawalQueue.sol


Uninitialized testing: Check that default values are returned by view calls:

| Test name | Description | Happy Case | Implemented |
|-----------| -----------|-------------|-------------|
|           | withdrawalDelay() returns zero. | NA | No |
|           | getPendingWithdrawals returns a zero length array | NA | No |


Control function tests: 

| Test name | Description | Happy Case | Implemented |
|-----------| -----------|-------------|-------------|
|           | __FlowRateWithdrawalQueue_init() configures the default withdrawal delay. | Yes | No |
|           | _setWithdrawalDelay can confugre a withdrawal delay | Yes | No |



Operational function tests: 

| Test name | Description | Happy Case | Implemented |
|-----------| -----------|-------------|-------------|
|           | _enqueueWithdrawal | Yes | No |
|           | _enqueueWithdrawal with two different tokens. | Yes | No |
|           | _dequeueWithdrawal with no elements in the queue | Yes | No |
|           | _dequeueWithdrawal with one available element in the queue | Yes | No |
|           | _dequeueWithdrawal with two available elements in the queue | Yes | No |
|           | _dequeueWithdrawal with one element in the queue, but not available | Yes | No |
|           | _dequeueWithdrawal with two elements in the queue, but only one is available | Yes | No |
|           | _dequeueWithdrawal with three elements in the queue, but only two are available | Yes | No |
|           | Enqueue one token, dequeue the token, and repeat multiple times. | Yes | No |


## Flow Rate Withdrawal Queue
This section defines tests for contracts/root/flowrate/RootERC20PredicateFlowRate.sol


Uninitialized testing: Check that default values are returned by view calls:

| Test name | Description | Happy Case | Implemented |
|-----------| -----------|-------------|-------------|
|           | paused() returns false. | NA | No |
|           | largeTransferThresholds returns 0 for a  returns a zero length array | NA | No |


Control functions testing: 

| Test name | Description | Happy Case | Implemented |
|-----------| -----------|-------------|-------------|
|           | pause() | Yes | No |
|           | pause() bad auth. | No | No |
|           | unpause() | Yes | No |
|           | unpause() bad auth. | No | No |
|           | activateWithdrawalQueue() | Yes | No |
|           | activateWithdrawalQueue() bad auth. | No | No |
|           | deactivateWithdrawalQueue() | Yes | No |
|           | deactivateWithdrawalQueue() bad auth. | No | No |
|           | setRateControlThreshold() | Yes | No |
|           | setRateControlThreshold() bad auth| No | No |
|           | grantRole() | Yes | No |
|           | grantRole() bad auth| No | No |


Operational functions testing: 

| Test name | Description | Happy Case | Implemented |
|-----------| -----------|-------------|-------------|
|           | _withdraw() small amount, no quue | Yes | No |
|           | _withdraw() with data parameter too small | No | No |
|           | _withdraw() with unconfigured child / root token | No | No |
|           | _withdraw() with large value | Yes | No |
|           | _withdraw() with unconfigured token | Yes | No |
|           | _withdraw() with withdrawal queue active | Yes | No |
|           | finaliseQueueWithdrawal() with no queued withdrawal | Yes | No |
|           | finaliseQueueWithdrawal() with one queued withdrawal that is available | Yes | No |
|           | finaliseQueueWithdrawal() with two queued withdrawals that are available | Yes | No |
|           | finaliseQueueWithdrawal() with three queued withdrawals that are available | Yes | No |
|           | finaliseQueueWithdrawal() with one queued withdrawals that is not available | Yes | No |
|           | finaliseQueueWithdrawal() with four queued withdrawals, three of which are available | Yes | No |
