function outp_create_template()
% ------------------------------------------------------------------
% 功能 : 此函式產生outp 3個主要的block，但是有些功能仍有手動完成 
% 版本 : 1.0.0 %
% 日期 : 2013/9/5
% 作者 : 黃銀大
% ------------------------------------------------------------------
% Update @ 2014/6/23 by Kian, Add input and output bus.
%% 設定位置及 block size 設定
x0 = 300; % 會隨 subsystem創建而改變 %
y0 = 50;
y9 = 50;
topblock_w = 400;
topblock_interval = 300;
GOFROM_TAG = 'PowerUpDn';
def_var_str = '_inAPP';

x0_in = 50;
y0_in = 50;
y0_ut = 50;

const_block_w = 200;
const_block_h = 25;

switch_block_w = 30;
switch_block_h = 100;

gofrom_block_w = 100;
gofrom_block_h = 25;

out_block_w = 30;
out_block_h = 14;

in_block_w = 30;
in_block_h = 14;

sub_block_w = 150;
sub_block_h = 60;

unit_block_w = 50;
unit_block_h = 20;

x0_def = 400;
x1_def = x0_def + 350;
x2_def = x1_def + 300;
y0_def = 50;
y0_def_interval = 80;

x0_ove = 100;
x1_ove = x0_ove + in_block_w + 300;  % override %
x2_ove = x1_ove + sub_block_w + 300; % out %
y0_ove = 20;
y0_ove_interval = 50;

x0_lim = 100;                        % in %
x1_lim = x0_lim + in_block_w + 200;   % limit %
x2_lim = x1_lim + sub_block_w + 50;  % raw %
x3_lim = x2_lim + sub_block_w + 70;  % protect %
x4_lim = x3_lim + sub_block_w + 50;  % unit convert %
x5_lim = x4_lim + sub_block_w + 100; % out %
y0_lim = 50;
y0_lim_interval = 50;

y0_def = y0_def + ((max([out_block_h,gofrom_block_h,switch_block_h,const_block_h])) / 2);
y0_def_interval = y0_def_interval + ((max([out_block_h,gofrom_block_h,switch_block_h,const_block_h])) / 2);
y0_ove = y0_ove + ((max([out_block_h,in_block_h,sub_block_h])) / 2);
y0_ove_interval = y0_ove_interval + ((max([out_block_h,in_block_h,sub_block_h])) / 2);
y0_lim = y0_lim + ((max([out_block_h,in_block_h,sub_block_h,unit_block_h])) / 2);
y0_lim_interval = y0_lim_interval + ((max([out_block_h,in_block_h,sub_block_h,unit_block_h])) / 2);

%% 讀取 bus 訊號
[file_name,PathName] = uigetfile({'*.xls;*.xlsx;', 'Excel Files (*.xls, *.xlsx)'; '*.*', 'All Files (*.*)'}, 'Select target file'); % User select DD file.
[num_o,txt_o,raw_o]=xlsread([PathName file_name],'signals');

% Find out module name
outbus_name = strread(file_name(4:end), '%s', 'delimiter', '.');
outbus_name = char(outbus_name(1));

% Combine outputs bus name
outbus = ['B' outbus_name '_outputs'];
outp_bus = evalin('base', outbus);

% Extract bus info 
outp_info = bus_info(outp_bus);
bus_size = size(outp_info);
bus_number = bus_size(:,1);
tmpNode = txt_o(1:end,2);
tmpSig = txt_o(1:end,1);

% Extract inputs signals
tmpOutputs = [];
tmpOutputs = union(tmpOutputs, strmatch('input', lower(tmpNode)));
Inbl = tmpSig(tmpOutputs);
Inbllen = length(Inbl);
sname = [];

new_model = ['outp_temp_' datestr(now,30)];
new_system(new_model);
open_system(new_model);
top_model = new_model;

load_system simulink
load_system siltestlib

% Create Outfit mask
srcT = 'built-in/SubSystem';
dstT = [top_model '/' outbus_name]; 
OUTP = add_block(srcT,dstT,'position',[400,190,650,(bus_number*75)+320]); 
Main_model = dstT;

% 加入一個subsystem %
srcT = 'built-in/SubSystem';
dstT = [Main_model '/' lower(outbus_name)];    
h_outp = add_block(srcT,dstT,'position',[400,250,800,(Inbllen*50)+350]); 
new_model = dstT;

if (nargin > 0 )
    error('too many arguments');
end

%% Create Input port , bus selector, test input and output
%Figure out input signals of outp model
for i = 1:Inbllen
    OpBus = Inbl{i,1}(1:5);
    sname1 = strread(OpBus, '%s', 'delimiter', '_');
    sname = [sname; sname1];
    Insname = char(Inbl(i,1));
    srcT = 'simulink/Sources/In1';
    dstT = [new_model '/' Insname];          
    subinp = add_block(srcT,dstT,'position',[x0-250,y9+1240,x0-220,y9+1250]);
    y9 = y9 +31;
end

BusOut = union(sname, sname);
count = 1;

% Add in block%
Inp_number = length(BusOut);

% Extract bus name from signals
for i = 1:Inp_number
Busout = char(BusOut(i,1));
busname = [Busout '_outputs'];
busname(1) = 'B';
InBus = [];
InBus = union(InBus, strmatch(Busout, Inbl));
SelSig = Inbl(InBus);
Selout_number = length(SelSig);
sname1 = num2str(0);

% Add input bus on module layer
srcT = 'simulink/Sources/In1';
dstT = [Main_model '/' busname];          
tmpb0 = add_block(srcT,dstT,'position',[x0_in,y0_in+50+(Selout_number*15) ,x0_in+30,y0_in+65+(Selout_number*15)],'usebusobject','on','busobject', busname);  

% Add input bus on module mask layer
srcT = 'simulink/Sources/In1';
dstT = [top_model '/' busname];          
inport = add_block(srcT,dstT,'position',[x0_in,y0_ut+160 ,x0_in+30,y0_ut+175],'usebusobject','on','busobject', busname);

% Add system into module mask layer 
Busout(1) = 'B';
mask_name = [Busout '_BUS'];
srcT = 'built-in/SubSystem';
dstT = [top_model '/' mask_name];    
mask_bus = add_block(srcT,dstT,'position',[150,y0_ut+150,300,y0_ut+190]);
mask_model = dstT;

% Add input bus inside module mask layer
srcT = 'simulink/Sources/In1';
dstT = [mask_model '/' busname];          
maskin = add_block(srcT,dstT,'position',[x0_in,65 ,x0_in+30,80],'usebusobject','on','busobject', busname);

% Add output bus inside module mask layer
srcT = 'simulink/Sinks/Out1';
dstT = [mask_model '/' busname(1:(end-1))];          
maskout = add_block(srcT,dstT,'position',[x0_in+1150,50+(Selout_number*33) ,x0_in+1180,(Selout_number*33)+65],'usebusobject','on','busobject', busname);

% Add line 
input = get(inport, 'name');
mbus = get(mask_bus, 'name');
outfit = get(OUTP, 'name');
add_line(top_model, [input, '/1'], [mbus, '/1']);
add_line(top_model, [mbus, '/1'], [outfit, '/' num2str(i)]);

y0_utprev = y0_ut;
y0_ut = 50;

% Add bus selector
for j = 1:Selout_number
    % Gather all signals into a cell    
    sname=char(SelSig(j,1));            
    sname1= strcat(sname1,',',sname);

    % Determine data type of signals
    sdtype_locate = strfind(char(SelSig(j,1)), '_');
    sdtype = SelSig{j,1}((sdtype_locate(2)+1):end);
    
    switch sdtype
    case 'flg'
        sunit = 'boolean';    
    case 'enum'
        sunit = 'uint8';
    case 'cnt'
        sunit = 'uint8';
    case 'raw32'
        sunit = 'uint32';
    otherwise
        sunit = 'single';    
    end

    % Add Test input blocks
    srcT = 'siltestlib/Test Input';
    dstT = [mask_model '/' sname '_T'];          
    testin = add_block(srcT,dstT,'position',[x0_in+100,y0_ut+75 ,x0_in+330,y0_ut+120], 'varname', sname, 'Showname', 'off');

    % Add Data type conversion blocks
    srcT = 'simulink/Signal Attributes/Data Type Conversion';
    dstT = [mask_model '/' sname '_D'];          
    Dtype = add_block(srcT,dstT,'position',[x0_in+400,y0_ut+80 ,x0_in+480,y0_ut+115], 'OutDataTypeStr', sunit, 'Showname', 'off');
    y0_ut = y0_ut + 55;
    
    add_line(mask_model, [sname, '_T/1'], [sname, '_D/1']);
end
y0_ut = y0_utprev;
sname1=sname1(3:length(sname1));

%Add bus assignment blocks
srcT = 'simulink/Signal Routing/Bus Assignment';
dstT = [mask_model '/Bus Assignment' Busout];          
BusAsig = add_block(srcT,dstT,'position',[x0_in+600,60 ,x0_in+1030,60+(Selout_number*65)]);
set_param(BusAsig, 'AssignedSignals', sname1);

% Add bus selector in outer mask
srcT = 'simulink/Signal Routing/Bus Selector';       
dstT = [Main_model '/Bub Selector' sname1];          
tmpb1 = add_block(srcT,dstT,'position',[x0_in+150,y0+50 ,x0_in+155,y0+50+(Selout_number*38)]);
set_param(tmpb1, 'outputsignals', sname1);
y0 = y0 + (Selout_number*40);
y0_in = y0_in + (Selout_number*40);
y0_ut = y0_ut + 55;

% Add line between blocks
blk_in = get(tmpb0, 'name');
blk_sel =get(tmpb1, 'name');
outp_in = get(h_outp, 'name');
bus_asig = get(BusAsig, 'name');
mask_in = get(maskin, 'name');
mask_out = get(maskout, 'name');

hl = add_line(Main_model,[blk_in, '/1' ], [blk_sel, '/1']);
add_line(mask_model, [mask_in, '/1'], [bus_asig, '/1']);
add_line(mask_model, [bus_asig, '/1'], [mask_out, '/1']);
for k = 1:Selout_number
add_line(mask_model, [char(SelSig(k,:)), '_D/1'], [bus_asig, '/' num2str(k+1)]);
h2 = add_line(Main_model,[blk_sel, '/' num2str(k)], [outp_in, '/' num2str(count)]);
count = count +1;
end
end

% Add trigger block
srcT = 'simulink/Ports & Subsystems/Trigger';       
dstT = [Main_model '/' 'trig_' outbus_name];          
tmpb1 = add_block(srcT,dstT,'position',[x0+270,y0-2370 ,x0+285,y0-2350]);
set_param(tmpb1, 'TriggerType', 'function-call');

% Add function generation
srcT = 'simulink/Ports & Subsystems/Function-Call Generator';       
dstT = [top_model '/Function-Call Generator' ];          
fcall = add_block(srcT,dstT,'position',[x0+120,y0-940 ,x0+155,y0-920]);
set_param(fcall, 'sample_time', 'C_TASK_10MS_S');

% Add model info block
srcT = 'simulink/Model-Wide Utilities/Model Info';       
dstT = [Main_model '/Model Info' ];          
tmpb2 = add_block(srcT,dstT,'position',[x0-100,y0-2370 ,x0+185,y0-2350]);
set_param(tmpb2, 'DisplayStringWithTags', '$Id: outp.mdl 0000 2013-09-11 09:48:36Z brian $' , 'MaskDisplayString', '$Id: outp.mdl 0000 2013-09-11 09:48:36Z brian $');

% Add line 
fnc_call = get(fcall, 'name');
add_line(top_model, [fnc_call, '/1'], [outfit, '/trigger'], 'Autorouting', 'on');


%% subsystem outputs
sname1 = '';

% Add system into module mask layer for output test 
mask_name = [outbus_name '_BUS'];
srcT = 'built-in/SubSystem';
dstT = [top_model '/' mask_name];    
mask_bus = add_block(srcT,dstT,'position',[680,y0_ut-15,830,y0_ut+25]);
mask_model = dstT;

if (bus_number~=0)
    y0 = 55;
    count = 1;
   
    for i = 1:bus_number   
        sname = char(outp_info(i,1));        
        sbtype = char(outp_info(i,3));         
        sbunit = char(outp_info(i,4));        
        
        % Add outputs block %
        srcT = 'simulink/Sinks/Out1';
        dstT = [new_model '/' sname];
        tmpb = add_block(srcT,dstT,'position',[x0, y0-(out_block_h/2)+1250, x0+out_block_w, y0+(out_block_h/2)+1250]);      
        
        sname1 = [sname1 sname];
        sname1 = [sname1 ','];
        
        % Add test output blocks in output mask
        srcT = 'siltestlib/Test Output';
        dstT = [mask_model '/Test Output' sname '_OI'];          
        test_out = add_block(srcT,dstT,'position',[x0_in+370,y0+60 ,x0_in+530,y0+105],'Showname', 'On','varname',sname, 'Showname', 'Off');
        
        % Add signal data type conversion into output mask
        srcT = 'simulink/Signal Attributes/Data Type Conversion';
        dstT = [mask_model '/' sname '_OD'];          
        odtype = add_block(srcT,dstT,'position',[x0_in+300,y0+70 ,x0_in+350,y0+95],'OutDataTypeStr', 'double', 'Showname', 'off');        
        
        tout = get(test_out, 'name');
        out_dtype = get(odtype, 'name');
        add_line(mask_model, [out_dtype, '/1'], [tout, '/1']);
        
        y0 = y0 + 50;        
        
        if strcmp(sbtype,'uint32') && strcmp(sbunit,'raw32')
            continue;
        end
        
        count = count + 1;
    end
sname1 = sname1(1:(end-1));
   
 
% Add input port for output test mask
srcT = 'simulink/Sources/In1';
dstT = [mask_model '/' outbus];          
inport = add_block(srcT,dstT,'position',[x0_in,y0_ut-170 ,x0_in+30,y0_ut-155],'Showname', 'On','usebusobject','on','busobject', outbus);

% Add bus selector in outer mask
srcT = 'simulink/Signal Routing/Bus Selector';       
dstT = [mask_model '/Bub Selector' outbus];          
tmpb1 = add_block(srcT,dstT,'position',[x0_in+70,y0-45 ,x0_in+75,y0-5+(Selout_number*65)]);
set_param(tmpb1, 'outputsignals', sname1);

mo_in = get(inport, 'name');
bus_sel = get(tmpb1, 'name');
add_line(mask_model, [mo_in, '/1'], [bus_sel, '/1']);



for i = 1 : bus_number
    add_line(mask_model, [bus_sel, '/' num2str(i)], [char(outp_info(i,1)), '_OD/1']);
end

    bus_hight = block_resize(h_outp,50,bus_number,0); % 0 表示目前沒有使用 %        
end

%% 創建 bus creator 
srcS = 'simulink/Signal Routing/Bus Creator';    
dstS = [Main_model '/Bus_Creator_outp'];
h1 = add_block(srcS, dstS,'showname','off','position',[x0+700,35,x0+705,20+bus_hight],'inputs',num2str(bus_number),'usebusobject','on','busobject','BOUTP_outputs');
blpb0 = get(h_outp, 'name');
blpb1 = get(h1, 'name');
for i = 1:bus_number
sname = char(outp_info(i,1)); 
LineOut = add_line(Main_model, [blpb0, '/' num2str(i)], [blpb1, '/' num2str(i)]);
hObject = get(LineOut, 'object');
set(hObject, 'SignalPropagation', 'on');
set_param(LineOut,'name',['<' sname '>']);
end

% Create outport for OUTP
srcT = 'simulink/Sinks/Out1';       
dstT = [Main_model '/' outbus];          
tmpb1 = add_block(srcT,dstT,'position',[x0+800,((bus_hight+40)/2),x0+830,((bus_hight+40)/2)+15],'usebusobject','on', 'busobject','BOUTP_outputs' );        
set_param(tmpb1, 'OutDataTypeStr', 'Bus:BOUTP_outputs', 'ShowName', 'on');
Op1 = get(tmpb1, 'name');
OpLine = add_line(Main_model,[blpb1, '/1'], [Op1, '/1']); 
set_param(OpLine, 'name', outbus);
hObject = get(OpLine, 'object');
set(hObject, 'MustResolveToSignalObject', 1);   

output_mask = get(mask_bus, 'name');
add_line(top_model,[outfit, '/1'],[output_mask, '/1']);
%%
disp('Create done Q___Q');
disp('1.If user have any question plz contact lingling kuo! ^.<');
%disp('2.heartbeat signal does not care about the PowerUpDn.');
%disp('3.careful the torque signal when the unit change from Nm to pct.')
%disp('4.some signals in sub_limit block need to be link by manual.');
end

%%
function [block_b] = block_resize(hsub, block_t, port_num, v_interval)
port_interval = 30;

if (port_num <= 10)
    port_interval = 32;
end

xsize = get_param(hsub,'position');  
xsize(2) = block_t;
xsize(4) = xsize(2) + port_num * port_interval - 15;
if (xsize(4) - xsize(2)) < 100 
    xsize(4) = xsize(2) + 100;
end  
set_param(hsub,'position',xsize);       
block_b = xsize(4) + v_interval;
end