%% parse the ceph pg dump (plain) file to see if the pg distribution is even.
%% how to use: 
%% 1. run "ceph pg dump >> ceph.pg.dump" to get the dump file; possibly "ceph osd tree" to map osd id to hostname
%% 2. specify the full filename 
%% 3. specify the total pg numbers and node numbers, the rep/ec type (n_num)
%% 
%% jun.xu@wdc.com

%% configuration area
filename='E:\Dropbox\Report\ceph\shell\ceph.pg.dump';
pg_num=512;
node_num=11;


fid=fopen(filename);
if fid<0
    'error in openning the file...'
    break;
end
tline=fgetl(fid);

prot_type=1;

if prot_type==1
    ec_num=3; % =m+k
    n_num=ec_num;
else
    rep_num=2;
    n_num=rep_num;
end

% node_pg_mat extract the pg pairs as a matrix
node_pg_mat=zeros(pg_num,n_num);

i=0;
while ischar(tline)
    idx1=strfind(tline,'[');
    if ~isempty(idx1)
        a=size(tline,2);
        tempstr=tline(idx1(1)+1:a);
        i=i+1;
        if prot_type==1
            nodes=sscanf(tempstr,'%d,%d,%d,%*s');
            node_pg_mat(i,:)=(nodes(1:ec_num))';
        else
            nodes=sscanf(tempstr,'%d,%d,%*s');
            node_pg_mat(i,:)=(nodes(1:rep_num))';
        end              
        
        if i==pg_num
            break;
        end
    end
    tline=fgetl(fid);
end

% node_count records the number of associate pgs for each osd
node_count=zeros(node_num,1);
for j=1:n_num
    for i=1:node_num
        [x,y]=find(node_pg_mat(:,j)==(i-1));
        node_count(i)=node_count(i)+size(x,1);
    end
end

% inter_node records the how one osd assoicates with others via PG maps

inter_node=zeros(node_num,node_num);
for i=1:size(node_pg_mat,1)
    for j=1:n_num
        for k=1:n_num
                if j~=k
                    inter_node(node_pg_mat(i,j)+1,node_pg_mat(i,k)+1)=inter_node(node_pg_mat(i,j)+1,node_pg_mat(i,k)+1)+1;
                end
        end
    end
end


