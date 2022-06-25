# PL/SQL Application Locking

PL/SQL Application Locking is a core PL/SQL framework that implements logical locking of objects at application level for applications that use Oracle databases. You can download and integrate it free in your application that uses Oracle databases or translate it for Microsoft, Postgres or other databases. For a custom and complex implementation please check the <a href="https://github.com/lucienlazar/plsql-application-locking#need-a-consultant">Need a Consultant?</a> section and contact me at https://www.lucianlazar.com/.

# Context

A multi-user application must control concurrency, the simultaneous access of the same data by many users, in order to ensure consistency and performance.

# Problem

In a multi-user environment it is easy to have concurrency issues. For instance, two or more users may need the same object at the same time. These concurency issues can be solved automatically by the database using database-level locking, but this may lead to stability issues and performance issues thatcan be very costly. 

# Solution

Instead of counting only on locks set by the database, it is more efficient to use explicit locking at application level. When the application starts a process that needs an object, we mark the object as locked manually at the correct point in time by explicit calls from the client. When the application finishes the process and does not need the object, it removes the lock. It is a simple and efficient usage of locking that reduces the database load and ensures consistency and performance.

# PL/SQL Application Locking Framework

The framework consists in two tables: process runs and application locks and two packages: processing and application locking. This section explains the essential characteristics of the objects and has links to the <a href="https://github.com/lucienlazar/plsql-application-locking/wiki">wiki</a> with technical details of the structure, parameters and logic.

The process runs table and the processing package are generic and can map to existing objects in your application. The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Process-Runs-Table">process runs table</a> stores process runs identified uniquely by a run id and having as attributes start time, end time and a run status that can be running, completed successfully or failed. The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Processing-Package">processing package</a> has two procedures: start process that starts a process with status running and end process that completes a process run and updates its status to successful or failed.

The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Application-Locks-Table">application locks table</a> is the core of the framework and stores the logical locks set by the client. A lock is identified uniquely by a lock id, is set on a certain object, by a certain process run id and can have three modes: shared, write exclusive or full exclusive. 

The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Application-locking-package">application locking package</a> contains the logic of the framework encapsulated in four procedures: acquire lock that adds a logical lock to a certain object by a certain run id, respecting an <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Acquire-Lock-Algorithm">algorithm</a> that allows upgrading certain lock modes, release locks that deletes the locks at the end of a process, get locks that lists the locks on a certain object and release orphan locks that deletes orphan locks on a certain resource left by completed process runs.

# Download and Install

You can download and run the <a href="https://github.com/lucienlazar/plsql-application-locking/blob/main/objects.sql">objects.sql</a> script that creates all the objects contained by the framework. For technical details about the usage of all procedures check the <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/Objects">objects page</a> in wiki. You will need to have access to an Oracle database to run the script there or you can translate it for Microsoft, Postgres or other databases.

You can replace the process runs table and the processing package with existing objects in your application and replace their references in the application locking package. 

# Demo

You can download and check the <a href="https://github.com/lucienlazar/plsql-application-locking/blob/main/demo.sql">demo.sql</a> script that contains examples of using the framework and handle different flows. The <a href="https://github.com/lucienlazar/plsql-application-locking/wiki/demo">demo page</a> in wiki contains more technical details about the flows in the testing scenarios.

# License

You can download and integrate free the plsql-application-locking framework in your PL/SQL code and in your application. 

# Need a Consultant?

Contact me on my website https://www.lucianlazar.com/ for any consulting enquiries. 

I can provide custom and complex implementations with advanced features like:
* extended acquire lock procedure with serializing access to resources, handling concurrency issues, adding retry modes and exception handling
* change lock procedure that allows upgrading or downgrading a lock
* extended procedure to release orphan locks on resource including exception handling, performance tweaks and more possible release conditions
* release all orphan locks procedure, called as part of a clean-up process in case of emergency.
