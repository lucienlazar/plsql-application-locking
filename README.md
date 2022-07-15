# PL/SQL Application Locking

PL/SQL Application Locking is a core PL/SQL framework that implements logical locking of objects at application level for applications that use Oracle databases. You can download and integrate it free in your application or translate it for Microsoft, Postgres or other databases. For a custom and complex implementation please check the <a href="https://github.com/lucienlazar/plsql-application-locking#nextended-functionality">Extended Functionality</a> section and contact me at https://www.lucianlazar.com/.

# Why Application Locking?

In multi-user application with lots of conccurent users that process big amounts of data, we can get wait events and deadlocks because the database-level locking can't handle the load. To decrease the load on the database, we can add a new layer in front of database-level locking where the application sets the locks. When the application starts a process that needs an object, it marks the object in the new layer as locked. When the application finishes the process and does not need the object anymore, it removes the lock from that layer. It is a simple and efficient usage of logical locking that reduces the load on the database-level locking, reduces the database load altogether and ensures consistency and performance.

# PL/SQL Application Locking Framework

The framework consists in two tables: process runs and application locks and two packages: processing and application locking. This section explains the essential characteristics of the objects and has links to the <a href="https://github.com/lucienlazar/plsql-application-locking/wiki">wiki</a> with technical details of the structure, parameters and logic.

The process runs table and the processing package are generic and can map to existing objects in your application. The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Process-Runs-Table">process runs table</a> stores process runs identified uniquely by a run id and having as attributes start time, end time and a run status that can be running, completed successfully or failed. The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Processing-Package">processing package</a> has two procedures: start process that starts a process with status running and end process that completes a process run and updates its status to successful or failed.

The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Application-Locks-Table">application locks table</a> is the core of the framework and stores the logical locks set by the client. A lock is identified uniquely by a lock id, is set on a certain object, by a certain process run id and can have three modes: shared, write exclusive or full exclusive. 

The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Application-locking-package">application locking package</a> contains the logic of the framework encapsulated in four procedures: acquire lock that adds a logical lock to a certain object by a certain run id, respecting an <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Acquire-Lock-Algorithm">algorithm</a> that allows upgrading certain lock modes, release locks that deletes the locks at the end of a process, get locks that lists the locks on a certain object and release orphan locks that deletes orphan locks on a certain resource left by completed process runs.

# Download and Install

You can download and run the <a href="https://github.com/lucienlazar/plsql-application-locking/blob/main/objects.sql">objects.sql</a> script that creates all the objects contained by the framework. For technical details about the usage of all procedures check the <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Objects">objects page</a> in wiki. You will need to have access to an Oracle database to run the script there or you can translate it for Microsoft, Postgres or other databases.

You can replace the process runs table and the processing package with existing objects in your application and replace their references in the application locking package. 

# Demo

You can download and check the <a href="https://github.com/lucienlazar/plsql-application-locking/blob/main/demo.sql">demo.sql</a> script that contains examples of using the framework and handle different flows. The demo contains all the flows of using the PL/SQL Application Locking framework with different scenarios for acquire locks, release locks and release orphan locks. The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/demo">demo page</a> in wiki contains more technical details about the flows in the testing scenarios.

### Acquire Locks

We start two process runs and set different application locks on two tables for these two processes. Only one process can set a write exclusive application lock on a table at a time to write in it and two parallel processes can set shared application locks on the same table at the same time to read from it.

### Release Locks

We complete the two process runs and release the application locks for one of these two processes. The first process completes successfully and releases its locks, while the second process fails and does not release its locks, leaving behind an orphan lock in the system.

### Release Orphan Locks

We start a third process that needs to use a table which remained locked by another completed process and see how it releases that orphan lock. After failing to acquire a lock on the table already locked, the third process checks the locks on that resource, confirms that there is an orphan lock and releases it. After the orphan lock is released, the third process will be able to acquire the lock on the table.

# License

You can download and integrate free the plsql-application-locking framework in your PL/SQL code and in your application. 

# Extended Functionality

For a custom implementation with high concurency that needs high performance and stability we can extend its functionality with advanced features like:

* extended acquire lock mechanism with serializing access to resources, retry modes and exception handling
* upgrade and downgrade lock mechanism
* extended release orphan locks mechanism with exception handling, performance tweaks and more possible release conditions
* release all orphan locks mechanism included in a clean-up process ran in case of database recovery.

Contact me on my website https://www.lucianlazar.com/ and we can collaborate to tailor the framework to your specific needs.
