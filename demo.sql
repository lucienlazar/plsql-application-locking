-- start process run P1
begin 
  processing.start_process('P1'); 
end;

select * from process_runs;

-- start process run P2
begin 
  processing.start_process('P2'); 
end;

select * from process_runs;

-- P1 acquires WX lock on resource T1
declare 
  v_lock_id integer;
begin 
  application_locking.acquire_lock('T1', 2, 1, v_lock_id); 
  dbms_output.put_line('Acquired lock id ' || v_lock_id);
end;

select * from application_locks;

-- P1 acquires S lock on resource T2
declare 
  v_lock_id integer;
begin 
  application_locking.acquire_lock('T2', 1, 1, v_lock_id); 
  dbms_output.put_line('Acquired lock id ' || v_lock_id);
end;

select * from application_locks;

-- P2 acquires S lock on resource T2
declare 
  v_lock_id integer;
begin 
  application_locking.acquire_lock('T2', 1, 2, v_lock_id); 
  dbms_output.put_line('Acquired lock id ' || v_lock_id);
end;

select * from application_locks;

-- complete process run P1 successfully and release its locks
declare
  v_released_locks integer;
  v_remaining_locks integer;
begin 
  processing.end_process(1, 1); 
  application_locking.release_locks_for_run(1, v_released_locks, v_remaining_locks);
  dbms_output.put_line('Released ' || v_released_locks);
  dbms_output.put_line('Remaining ' || v_remaining_locks);
end;

select * from process_runs;

select * from application_locks;

-- complete process run P2 with errors and do not release its locks
begin 
  processing.end_process(2, 2); 
end;

select * from process_runs;

select * from application_locks;

-- start process run P3
begin 
  processing.start_process('P3'); 
end;

select * from process_runs;

-- P3 tries to acquire FX lock on resource T2 but fails
declare 
  v_lock_id integer;
begin 
  application_locking.acquire_lock('T2', 3, 3, v_lock_id); 
  dbms_output.put_line('Acquired lock id ' || v_lock_id);
end;

select * from application_locks;

-- P3 checks the locks on resource T2
declare
  c_locks sys_refcursor;
  v_lock_id integer;
  v_lock_mode integer;
  v_run_id integer;
  v_run_status integer;
begin
  application_locking.get_locks_on_resource('T2', c_locks);
  loop
    fetch c_locks into v_lock_id, v_lock_mode, v_run_id, v_run_status;
    exit when c_locks%notfound;
    dbms_output.put_line('Lock id ' || v_lock_id);
    dbms_output.put_line('Mode ' || v_lock_mode);
    dbms_output.put_line('Run ' || v_run_id);
    dbms_output.put_line('Status ' || v_run_status);
  end loop;
end;

select * from application_locks;

-- P3 releases the orphan lock on resource T2
declare
  v_released_locks integer;
  v_remaining_locks integer;
begin 
  application_locking.release_orphan_locks_on_resource('T2', v_released_locks, v_remaining_locks);
  dbms_output.put_line('Released ' || v_released_locks);
  dbms_output.put_line('Remaining ' || v_remaining_locks);
end;

select * from application_locks;

-- clear tables and reset sequences
truncate table application_locks;
truncate table process_runs;
drop sequence process_runs_seq;
drop sequence application_locks_seq;
create sequence process_runs_seq start with 1 increment by 1;
create sequence application_locks_seq start with 1 increment by 1;
