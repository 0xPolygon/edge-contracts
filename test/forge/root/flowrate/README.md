# Test plan for RootERC20PreficateFlowRate and assocaited contracts

The following are unit tests for the flow rate control code.


## Flow Rate Detection
This section defines tests for contracts/root/flowrate/FlowRateDetection.sol. 
All of these tests are in test/forge/root/flowrate/FlowRateDetection.t.sol.

Uninitialized testing: Check that default values are returned by view calls:

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testUninitFlowRateBuckets       | flowRateBuckets(address) returns an empty bucket. | NA         |
| testUnWithdrawalQueueActivated  | withdrawalQueueActivated returns false.           | NA         |


Control functions tests:

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testActivateWithdrawalQueue     | _activateWithdrawalQueue().                       | Yes        |
| testDeactivateWithdrawalQueue   | _deactivateWithdrawalQueue() when withdrawalQueueActivate is true. | Yes |
| testSetFlowRateThreshold        | _setFlowRateThreshold() with valid values         | Yes        |
| testSetFlowRateThresholdBadToken | _setFlowRateThreshold() with token address = 0   | No         |
| testSetFlowRateThresholdBadCapacity | _setFlowRateThreshold() with capacity = 0     | No         |
| testSetFlowRateThresholdBadFillRate | _setFlowRateThreshold() with refill rate = 0  | No         |

Operational functions tests:

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testUpdateFlowRateBucketSingle  | _updateFlowRateBucket() with a single call for a configured token | Yes |
| testUpdateFlowRateBucketMultiple | _updateFlowRateBucket() with a multiple calls for a configured token | Yes |
| testUpdateFlowRateBucketOverflow | _updateFlowRateBucket() when the bucket overflows | Yes       |
| testUpdateFlowRateBucketJustEmpty | _updateFlowRateBucket() when the bucket is exactly empty. | Yes |
| testUpdateFlowRateBucketEmpty | _updateFlowRateBucket() when the bucket has underflowed. | Yes  |
| testUpdateFlowRateBucketAfterEmpty | _updateFlowRateBucket() after the bucket was empty. | Yes  |
| testUpdateFlowRateBucketUnconfigured | _updateFlowRateBucket() unconfigured bucket. | No        |


## Flow Rate Withdrawal Queue
This section defines tests for contracts/root/flowrate/FlowRateWithdrawalQueue.sol


Uninitialized testing: Check that default values are returned by view calls:

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testUninitWithdrawalQueue       | withdrawalDelay() returns zero.                   | NA         |
| testUninitPendingWithdrawals    | getPendingWithdrawals returns a zero length array.| NA         |
| testDequeueEmpty                | _dequeueWithdrawal with no elements in the queue. | Yes        |


Control function tests: 

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testInitWithdrawalQueue         | __FlowRateWithdrawalQueue_init().                 | Yes        |
| testSetWithdrawalDelay          | _setWithdrawalDelay can confugre a withdrawal delay | Yes      |



Operational function tests: 

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testEnqueueWithdrawal           | _enqueueWithdrawal                                | Yes        |
| testEnqueueTwoWithdrawals       | _enqueueWithdrawal with two different tokens.     | Yes        |
| testDequeueSingle               | _dequeueWithdrawal with one available element in the queue | Yes |
| testDequeueDouble               | _dequeueWithdrawal with two available elements in the queue | Yes |
| testDequeueNoneAvailable        | _dequeueWithdrawal with one element in the queue, but not available | Yes |
| testDequeueOneAvailable         | _dequeueWithdrawal with two elements in the queue, but only one is available | Yes |
| testDequeueTwoAvailable         | _dequeueWithdrawal with three elements in the queue, but only two are available | Yes |
| testEnqueueDequeueMultiple      | Enqueue one token, dequeue the token, and repeat multiple times. | Yes |


## Root ERC 20 Predicate Flow Rate
This section defines tests for contracts/root/flowrate/RootERC20PredicateFlowRate.sol


Uninitialized testing: Check that default values are returned by view calls:

| Test name                         |Description                                        | Happy Case |
|-----------------------------------| --------------------------------------------------|------------|
| testUninitPaused                  | paused() returns false.                           | NA         |
| testUninitLargeTransferThresholds | largeTransferThresholds returns 0 for a  returns a zero length array | NA |
| testWrongInit                     | Check calling RootERC20Predicate's initialize reverts. | NA    |


Control functions testing: 

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testPause                       | pause()                                           | Yes        |
| testPauseBadAuth                | pause() bad auth.                                 | No         |
| testUnpause                     | unpause()                                         | Yes        |
| testUnpauseBadAuth              | unpause() bad auth.                               | No         |
| testActivateWithdrawalQueue     | activateWithdrawalQueue()                         | Yes        |
| testActivateWithdrawalQueueBadAuth | activateWithdrawalQueue() bad auth.            | No         |
| testDeactivateWithdrawalQueue   | deactivateWithdrawalQueue()                       | Yes        |
| testDeactivateWithdrawalQueueBadAuth | deactivateWithdrawalQueue() bad auth.        | No         |
| testSetWithdrawDelay            | setWithdrawDelay()                                | Yes        |
| testSetWithdrawDelayBadAuth     | setWithdrawDelay() bad auth                       | No         |
| testSetRateControlThreshold     | setRateControlThreshold()                         | Yes        |
| testSetRateControlThresholdBadAuth | setRateControlThreshold() bad auth             | No         |
| testGrantRole                   | grantRole()                                       | Yes        |
| testGrantRoleBadAuth            | grantRole() bad auth                              | No         |


Operational functions testing: 

| Test name                       |Description                                        | Happy Case |
|---------------------------------| --------------------------------------------------|------------|
| testWithdrawal                  | _withdraw() small amount, no queue                | Yes        |
| testWithdrawalBadData           | _withdraw() with data parameter too small         | No         |
| testWithdrawalUnconfiguredToken | _withdraw() with unconfigured child / root token  | No         |
| testWithdrawalLargeWithdrawal   | _withdraw() with large value                      | Yes        |
|           | _withdraw() causing high flow rate | Yes | No |
|           | _withdraw() with withdrawal queue active | Yes | No |
|           | finaliseQueueWithdrawal() with no queued withdrawal | Yes | No |
|           | finaliseQueueWithdrawal() with one queued withdrawal that is available | Yes | No |
|           | finaliseQueueWithdrawal() with two queued withdrawals that are available | Yes | No |
|           | finaliseQueueWithdrawal() with three queued withdrawals that are available | Yes | No |
|           | finaliseQueueWithdrawal() with one queued withdrawals that is not available | Yes | No |
|           | finaliseQueueWithdrawal() with four queued withdrawals, three of which are available | Yes | No |

