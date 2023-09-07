clear all;
% setup parameters
n_ecasic=6;
dimx_ecasic = 8;
dimy_ecasic = (48+12);
ipaddr = '192.168.7.10';
port = 23;

fix_color_map = 0;
colorbar_lim = 250;%45 %установить предел цветовой шкалы / set colorbar limit

do_remap = 0;
integration = 1;


%open tcp connection
t = tcpip(ipaddr, port, 'NetworkRole', 'client', 'InputBufferSize', 10000); 
t.InputBufferSize=100000;
fopen(t);

%determine version
'sending'
fwrite(t, 'instrument ver');
[msg_reply, count] = fread(t, 31); 
'ok\n'
if strfind(char(msg_reply'), 'v3.') ~= 0
    protocol_ver = 3
else
    protocol_ver = 2
end

fwrite(t, 'instrument mode live');


% 2 graphics
a1=subplot(7,1,1:6);
a2=subplot(7,1,7);

for j=1:100000
    % acquire one frame
    fwrite(t, 'acq live');
    pdm_data = fread(t, 2880, 'uint32');
    pdm_data = swapbytes(uint32(pdm_data));
    ecasics_2d = reshape(pdm_data, [dimx_ecasic dimy_ecasic n_ecasic]); 
    % concatenation of 6 images into one image 48x48
    pdm_2d = [ecasics_2d(:,:,1)' ecasics_2d(:,:,2)' ecasics_2d(:,:,3)' ecasics_2d(:,:,4)' ecasics_2d(:,:,5)' ecasics_2d(:,:,6)'];
    % plot 2D image
    clims = [0 colorbar_lim];
    
    pdm_2d_remap = pdm_2d;
    
    for i = 1:n_ecasic % 6
         pdm_2d_new((i-1)*8+1:i*8,:) = pdm_2d_remap((i-1)*10+1:i*10-2,:); %показания с прибора
         pdm_2d_ki(i,:) = pdm_2d_remap(i*10-1,:);
    end;
    
    if fix_color_map==1
        %imagesc(a1,double(pdm_2d_remap/50000), clims);
        imagesc(a1,double(pdm_2d_new)/integration, clims);colorbar(a1);
        imagesc(a2,double(pdm_2d_ki)/integration, clims);colorbar;
    else
        imagesc(a1,double(pdm_2d_new)/integration);colorbar(a1);
        imagesc(a2,double(pdm_2d_ki)/integration);colorbar;
    end
    
    %if(j==1)
        colorbar;
    %end
    pause(1)   %0.1sec
end
cd ..

%% close tcp
fclose(t);
'port closed'
