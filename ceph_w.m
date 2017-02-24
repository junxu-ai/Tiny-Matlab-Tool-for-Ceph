%% this file is to parse the "ceph -w" output
%% how to use: run "ceph -w" to get the output (either copy from screen or use ">>"), and then change the filename below correspondingly.
%% jun.xu@wdc.com

%% configuration area
% file to be parsed
filename='E:\Dropbox\Report\ceph\shell\results\filestore_fill_test_cleanup_ceph_w.txt';
% total number of PGs; will be calcuated automatially later
pg_num=1024; 
% reserved parameters
% rep_num=2; ec_num=3; % =m+k
% node_num=4;

% in case that the batch write testing file is not synchozed with ceph_w, we shall add a shift value.
% time_shift=0.467 
% need to pre-define the status you are interested. --> will write a script to automatically include all status later.
pg_status={'active+clean','active+clean+scrubbing','active+clean+inconsistent','peering','active+clean+scrubbing+deep','stale+active+clean','stale+peering','stale+remapped','down+peering','down+remapped+peering','stale+activating+undersized+degraded','active+recovering+degraded','stale+active+undersized+degraded','stale+active+recovery_wait+degraded','stale+active+recovery_wait+undersized+degraded','active+recovery_wait+degraded','stale+activating+degraded'};



fid=fopen(filename);
if fid<0
    'error in openning the file...'
    break;
end
tline=fgetl(fid);

pg_status_num=size(pg_status,2);
pg_record=zeros(100000,pg_status_num);
time_record=zeros(100000,1);
use_record=zeros(100000,6);
pg_inc=10000;

i=0; line_cont=1;
while ischar(tline)
    % may add a line to omit [WRN]
    
    
    % get the status string
    idx0=strfind(tline,':');
    idx1=strfind(tline,';');
    idx6=strfind(tline,'/');
    
    if (size(idx0,2)>1) & (size(idx1,2)>=1) & (size(idx6,2)>=1)
        idx4=strfind(tline,',');
        
        str_len=size(tline,2);
        i=i+1;
        % collect the time information
        time_str=tline(1:26); % may change 26 for different format; % '2016-10-30 08:01:57.507576';
        time_record(i)=datenum(time_str,'yyyy-mm-dd HH:MM:SS.FFF');
        
        % collect the data usage information
        idx5=find(idx4>idx1(1),1,'first');
        usage_str=tline(idx1(1)+1:idx4(idx5)-1);
        use_record(i,1)=sscanf(usage_str,'%d%*s'); % data usage
        if ~isempty(strfind(usage_str,'kB'))
            use_record(i,1)=use_record(i,1)/1024^2;
        elseif ~isempty(strfind(usage_str,'MB'))
            use_record(i,1)=use_record(i,1)/1024;
        elseif ~isempty(strfind(usage_str,'GB'))
            % the following code is temprary to connect two "ceph -s"
            if (use_record(i-1,1)>=18990) && (use_record(i,1)<18990)
                use_record(i,1)=use_record(i,1)+18990;
            end
        end
        
        usage_str2=tline(idx4(idx5)+1:idx4(idx5+1)-1);
        use_record(i,2)=sscanf(usage_str2,'%d%*s'); % total usage
        
        idx7=find(idx4<idx6(1),1,'last');
        usage_str3 =tline(idx4(idx7)+1:str_len); %avaible / total
        use_record(i,3:4)=sscanf(usage_str3,'%d GB / %d GB avail');
        
        if i==1
            total_size=use_record(i,4);
        end
        
        
        % collect the status information
        status_str=tline(idx0(4)+1:idx1(1)-1);
        idx2=strfind(status_str,',');
        if isempty(idx2)
            status_term_num=1;
        else
            status_term_num=size(idx2,2)+1;
        end
        status_str_vec={};
        if status_term_num>1
            % separate the string
            for k=1:status_term_num
                if k==1
                    status_str_vec{k}=status_str(1:idx2(k)-1);
                elseif k<status_term_num
                    status_str_vec{k}=status_str((idx2(k-1)+1):(idx2(k)-1));
                else
                    status_str_vec{k}=status_str((idx2(k-1)+1):size(status_str,2));
                end
            end
        end
        % check which status
        % for convenience, we may also check status_str_vec with another
        % "for" loop
        for j=1:pg_status_num
            idx3=strfind(status_str,pg_status{j});
            if ~isempty(idx3)
                if status_term_num==1
                    temp_value=sscanf(status_str,'%d %*s');
                else
                    % find the exactly matched string
                    
                    find_right_str=0;
                    for ll=1:size(idx3,2)
                        
                        % there are 3 cases: first, between, and last;
                        if (status_str(idx3(ll)-1)==' ')
                            if idx3(ll)+size(pg_status{j},2)>size(status_str,2)
                                find_right_str=1;
                            elseif  (status_str(idx3(ll)+size(pg_status{j},2))==',')
                                find_right_str=1;
                            else
                                find_right_str=0;
                            end
                            
                            if find_right_str==1
                                if idx2>idx3(ll)
                                    % the first string
                                    temp_value=sscanf(status_str,'%d %*s');
                                else
                                    [a,b]=find(idx2<idx3(ll),1,'last');
                                    temp_value=sscanf(status_str(idx2(b)+1:idx3(ll)),'%d %*s');
                                    break;
                                end
                            end
                            
                        end
                    end
                    
                end
                pg_record(i,j)=temp_value(1);
            end
        end
        
        %% collect the transmission &  operation speed
        if size(idx1,2)>1
            so_str=tline(idx1(2)+1:str_len);
            use_record(i,5)=sscanf(so_str,'%d');
            if ~isempty(strfind(so_str,'kB'))
                use_record(i,5)=use_record(i,5)/1024;
            elseif ~isempty(strfind(so_str,'MB'))
                % use_record(i,1)=use_record(i,1)/1024;
                % not consider GB
            end
            idx10=strfind(so_str,',');
            o_str=so_str(idx10+1:size(so_str,2));
            use_record(i,6)=sscanf(o_str,'%d');
        else
            use_record(i,5)=NaN;
            use_record(i,6)=NaN;
        end
        
    end
    tline=fgetl(fid); line_cont=line_cont+1;
    if mod(line_cont,5000)==0
        disp(['processed ', int2str(line_cont), ' lines']);
    end
    
end
fclose(fid)
pg_record=pg_record(1:i,:);

non_zero_status=[];
for jj=1:pg_status_num
    idx_t=find(pg_record(:,jj)>0);
    if ~isempty(idx_t)
        non_zero_status=[non_zero_status,jj];
    end
end



% pg_record(:,1)=pg_num-sum(pg_record(:,2:pg_status_num),2);
time_record=time_record(1:i);
time_record(:)=(time_record(:)-time_record(1))*24; time_record=time_record+time_shift;
use_record=use_record(1:i,:);

figure;hold on; grid on;
stp={'-r',':b','--y','-.g','-k',':c','--m','-b','k:','y-','g:','r:','b--','k--','b-.','r-.','y-.'};
% for i=1:pg_status_num
%     plot(time_record,pg_record(:,i),stp{i});
% end

for i=1:size(non_zero_status,2)
    plot(time_record,pg_record(:,non_zero_status(i)),stp{i});
end

xlabel('time (hours)');
ylabel('PG number');
legend(pg_status{non_zero_status},'Location','NorthEastOutside');
title(['PG status changes (total' int2str(pg_num) ')']);

figure;
hold on; grid on;
for i=1:2
    plot(time_record,use_record(:,i),stp{i});
end
xlabel('time (hours)');
ylabel('usage (GB)');
legend('data', 'overall')
title(['storage usage change (total ' int2str(total_size) 'GB)'])

figure;
hold on; grid on;
for i=1:2
    plot(time_record,use_record(:,i)/total_size,stp{i});
end
xlabel('time (hours)');
ylabel('usage %');
legend('data used', 'total used')
title(['storage usage change (total ' int2str(total_size) 'GB)'])

figure;
hold on; grid on;
xx=use_record(:,2)-2*use_record(:,1);
plot(time_record,xx);
xlabel('time (hours)');
ylabel('usage (GB)');
legend('metadata')
title(['storage usage other than data (total ' int2str(total_size) 'GB)'])

figure;
hold on; grid on;
for i=1:2
    plot(time_record,use_record(:,i+2),stp{i});
end
xlabel('time (hours)');
ylabel('usage (GB)');
legend('avaiable', 'overall')
title(['storage available change (total ' int2str(total_size) 'GB)'])

figure
hold on; grid on;
[AX,H1,H2] = plotyy(time_record,use_record(:,5),time_record,use_record(:,6));
set(get(AX(1),'Ylabel'),'String','Througput (MBPS)')
set(get(AX(2),'Ylabel'),'String','Operation/s')
xlabel('Time (hours)')
title(['Observation via Ceph -w'])
set(H1,'LineStyle','o')
set(H2,'LineStyle','*')


figure
grid on;
plot(time_record,use_record(:,5),'o');
ylabel('Througput (MBPS)')
xlabel('Time (hours)')
title(['Observation via Ceph -w'])

figure
grid on;
plot(time_record,use_record(:,6),'o');
ylabel('Operation/s')
xlabel('Time (hours)')
title(['Observation via Ceph -w'])