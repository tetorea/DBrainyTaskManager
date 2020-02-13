# DBrainyTaskManager
a mix of GOAP and Utility-based AI in Dlang to make a multi-level task planner/manager

A library to create a system that manages a list of Actions in order to influence the system States.

The user creates his own States and possible Actions and a Goal State.
Each action can have a list of constraints which need to be solved in order to be started.

The System must then automatically find the list of Actions (= ActionPath) that will lead to the desired States. 
This list is then managed by the System which starts each actions and check their execution.
Statistics are used by the system to keep track of the efficiency of the action path used.

...
