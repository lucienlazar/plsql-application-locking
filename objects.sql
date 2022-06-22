drop table application_locks;
drop table process_runs;
drop sequence process_runs_seq;
drop sequence application_locks_seq;
/
create table process_runs(run_id integer, process_name varchar2(10), run_status integer, run_start timestamp, run_end timestamp);
comment on column process_runs.run_status is 'Run status: 0 = running, 1 = successful, 2 = failed';
alter table process_runs add constraint process_runs_pk primary key(run_id);
create sequence process_runs_seq start with 1 increment by 1;
/
create table application_locks(lock_id integer, resource_name varchar2(10), lock_mode integer, run_id integer);
comment on column application_locks.lock_mode is 'Lock mode: 1 = S, 2 = WX, 3 = FX';
alter table application_locks add constraint application_locks_pk primary key(lock_id);
create unique index application_lock_idx on application_locks(resource_name, run_id);
alter table application_locks add constraint application_locks_fk foreign key(run_id) referencing process_runs(run_id);
create sequence application_locks_seq start with 1 increment by 1;
/
create or replace package processing as
  procedure start_process(pi_process_name in varchar2);
  procedure end_process(pi_run_id in integer, 
                        pi_run_status in integer);
end;
/
create or replace package body processing as
  procedure start_process(pi_process_name in varchar2) as
  begin
    -- start a process with status 0 = running
    insert into process_runs(run_id, process_name, run_status, run_start, run_end)
    values (process_runs_seq.nextval, pi_process_name, 0, systimestamp, null);
  end;
  procedure end_process(pi_run_id in integer, 
                        pi_run_status in integer) as
  begin
    -- end a process with status 1 = successful or 2 = failed
    update process_runs
       set run_status = pi_run_status,
           run_end = systimestamp
     where run_id = pi_run_id;
  end;
end;
/
create or replace package application_locking as
  procedure acquire_lock(pi_resource_name in varchar2, 
                         pi_lock_mode in integer, 
                         pi_run_id in integer, 
                         po_lock_id out integer);
  procedure release_locks_for_run(pi_run_id in integer,
                                  po_released_locks out integer,
                                  po_remaining_locks out integer);
  procedure get_locks_on_resource(pi_resource_name in varchar2,
                                  po_locks out sys_refcursor);
  procedure release_orphan_locks_on_resource(pi_resource_name in varchar2,
                                             po_released_locks out integer,
                                             po_remaining_locks out integer);
end;
/
create or replace package body application_locking as 
  procedure acquire_lock(pi_resource_name in varchar2, 
                         pi_lock_mode in integer, 
                         pi_run_id in integer, 
                         po_lock_id out integer) as
    same_lock integer;
    other_lock integer;
  begin
    -- check if there is an existing lock on the object from same run
    select count(*) into same_lock 
      from application_locks 
     where resource_name = pi_resource_name and run_id = pi_run_id;
    -- proceed if there is no existing lock from same run
    if same_lock = 0 then
      -- check if there are existing locks on the object from other runs
      select nvl(max(lock_mode),0) into other_lock 
        from application_locks 
       where resource_name = pi_resource_name and run_id != pi_run_id;
      -- acquire lock respecting the algorithm
      if (pi_lock_mode = 1 and other_lock in (0,1,2)) -- add S only if there was maximum WX
      or (pi_lock_mode = 2 and other_lock in (0,1)) -- add WX only if there was maximum SHA
      or (pi_lock_mode = 3 and other_lock = 0) -- add FX only if there was no lock
      then
        insert into application_locks(lock_id, resource_name, lock_mode, run_id)
        values(application_locks_seq.nextval, pi_resource_name, pi_lock_mode, pi_run_id)
        returning lock_id into po_lock_id;  
      end if;
    end if;
  end;
  procedure release_locks_for_run(pi_run_id in integer,
                                  po_released_locks out integer,
                                  po_remaining_locks out integer) as
  begin
    delete application_locks where run_id = pi_run_id;
    po_released_locks := sql%rowcount;
    select count(*) into po_remaining_locks from application_locks where run_id = pi_run_id;
  end;
  procedure get_locks_on_resource(pi_resource_name in varchar2,
                                  po_locks out sys_refcursor) as
  begin
    open po_locks for
    select al.lock_id, al.lock_mode, al.run_id, pr.run_status
      from application_locks al
      join process_runs pr on al.run_id = pr.run_id
     where resource_name = pi_resource_name;
  end;
  procedure release_orphan_locks_on_resource(pi_resource_name in varchar2,
                                             po_released_locks out integer,
                                             po_remaining_locks out integer) as
  begin
    -- delete orphan locks on resource left by completed runs
    delete application_locks al
     where resource_name = pi_resource_name
       and exists (select 1
                     from process_runs pr
                    where al.run_id = pr.run_id
                      and run_status in (1,2));
    po_released_locks := sql%rowcount;
    select count(*) into po_remaining_locks from application_locks where resource_name = pi_resource_name;
  end;
end;
/