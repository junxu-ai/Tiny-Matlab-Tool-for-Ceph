%% parse the detailed output from "rados bench" (write) test
%% the parsed performance result is stored in "output_array" and corresponding time is in "time_record"
%% note that once we get the time/date informaiton, we convert it into a unique format (in second), and then change the offset. "time_record_org" records the original one
%% jun.xu@wdc.com

filename='E:\Dropbox\Report\ceph\shell\results\filestore_fill_test_cleanup.txt';
fid=fopen(filename);
if fid<0
    'error in openning the file...'
    break;
end

tline=fgetl(fid);

output_array=zeros(200000,8);
time_record=zeros(200000,1);

j=0; k=0; l=0;
while ischar(tline)
    str0=sscanf(tline,'%s%c');
    if (size(str0,2)>3) & strcmp(str0(1:3),'sec')
        for i=1:20
            tline=fgetl(fid);k=k+1;
            
            %   sec Cur ops   started  finished  avg MB/s  cur MB/s last lat(s)  avg lat(s)
            if ischar(tline)
                value0=sscanf(tline,'%d      %d        %d         %d   %f         %d    %f    %f');
                if isempty(value0) % | value0(1)==0
                    
                    continue;
                else
                    if value0(1)==0
                        j=j+1;
                        output_array(j,[1:6])=value0(1:6);
                    else
                        if size(value0,1)>=6
                            j=j+1;
                            if size(value0,1)==8
                                output_array(j,:)=value0;
                            else
                                output_array(j,[1:6])=value0(1:6);
                            end
                        end
                    end
                end
            end
            if i==20
                tline=fgetl(fid);k=k+1;
                %read the time stamp
                if isempty(strfind(tline,'min lat'))
                    tline=fgetl(fid);k=k+1;
                    break;
                end
                if ischar(tline)
                    l=l+1;
                    time_str=tline(1:26); % may change 26 for different format; % '2016-10-30 08:01:57.507576';
                    time_vec=datenum(time_str,'yyyy-mm-dd HH:MM:SS.FFF');
                    time_record(j-19:j)=time_vec*24*3600-(20:-1:1)';
                end
                
            end
        end
    else
        tline=fgetl(fid);k=k+1;
    end
    if k==15246
        disp('debug')
    end
    if mod(k,10000)==0
        disp(['Now processed ' int2str(k) ' lines']);
    end
end

fclose(fid);
%
% time_record2=zeros(j,1);
% time_inc=20:-1:1;
% j_res=mod(j,20);
% j_div=floor(j/20);
%
% time_record_bk=time_record;
% time_record=(time_record-time_record(1))*24*3600; % convert to seconds
% for i=1:j_div
%     time_record2((i-1)*20+1:i*20)=time_record(i)-time_inc;
% end
% for m=1:j_res
%     time_record2(i*20+m)=time_record(i)+m;
% end
%
% time_record2=time_record2*24;

idx=find(time_record>0,1,'first');
time_record_org=time_record;
time_record=time_record-time_record(idx);
figure;
%plot(output_array(1:j,1),output_array(1:j,5),'r');
idx=find(time_record>0);
plot(time_record(idx)/3600,output_array(idx,5),'b*')  %% in hour format
xlabel('time (hours)'); ylabel('throughput (MBPS)')
% plot(time_record(idx),output_array(idx,5))  %% in second format
% xlabel('time (seconds)'); ylabel('throughput (MBPS)')
hold on;
%legend('Instant 1','Instant 2')
grid on

% plot a zoomed figure in a small scale
idx2=find(output_array(idx,5)>150);
figure;
%plot(output_array(1:j,1),output_array(1:j,5),'r');
plot(time_record(idx(idx2))/3600,output_array(idx(idx2),5))  %% in hour format
xlabel('time (hours)'); ylabel('throughput (MBPS)')
% plot(time_record(idx),output_array(idx,5))  %% in second format
% xlabel('time (seconds)'); ylabel('throughput (MBPS)')
grid on;