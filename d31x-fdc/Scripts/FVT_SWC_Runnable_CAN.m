function FVT_SWC_Runnable_CAN()
cd ../documents/ARXML_output/

%% ------- Gather all CAN PDUs from CANx.arxml -------
length_CANX_cell = 0;
CANX_cell = cell(10000,3);
amount_PDU_total = 0;

for i = 1:6
    originalString = 'CAN.arxml';
    insertPosition = 4;
    CANX_arxml = [originalString(1:insertPosition-1), num2str(i), originalString(insertPosition:end)];
    fileID = fopen(CANX_arxml);
    CANX_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
    fclose(fileID);
    CANX_arxml = CANX_arxml{1};
    PDU_location_cell = find(contains(CANX_arxml,'<I-SIGNAL-I-PDU>'));
    amount_PDU_tmp= length(PDU_location_cell);
    for k = 1 : amount_PDU_tmp
        location_CAN_msg_name = PDU_location_cell(k)+1;
        CANX_cell(amount_PDU_total+k,1) = extractBetween(CANX_arxml((location_CAN_msg_name),1), '<SHORT-NAME>', '</SHORT-NAME>');
        location_time_period = location_CAN_msg_name + find(contains(CANX_arxml(location_CAN_msg_name:end),'<TIME-PERIOD>'), 1, 'first');
        CANX_cell(amount_PDU_total+k,2) = extractBetween(CANX_arxml(location_time_period,1), '<VALUE>', '</VALUE>');
        location_trigger_type = location_CAN_msg_name + find(contains(CANX_arxml(location_CAN_msg_name:end),'<TRANSFER-PROPERTY>'), 1, 'first') - 1;
        CANX_cell(amount_PDU_total+k,3) = extractBetween(CANX_arxml(location_trigger_type,1), '<TRANSFER-PROPERTY>', '</TRANSFER-PROPERTY>');
    end
    amount_PDU_total = amount_PDU_total + amount_PDU_tmp;
end

CANX_cell = CANX_cell(1:amount_PDU_total, : );

%% ------- Gather all CAN PDUs according to SWC_FDC.arxml -------
fileID = fopen('SWC_FDC_ORIGINAL.arxml');
SWCFDC_arxml_Updated = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
fclose(fileID);
SWCFDC_arxml_Updated = SWCFDC_arxml_Updated{1};

location_P_CAN = find(contains(SWCFDC_arxml_Updated,'<SHORT-NAME>P_CAN'));
amount_P_CAN = length(location_P_CAN);
P_port_cell = cell(amount_P_CAN,1);
for i = 1 : amount_P_CAN
    P_port_cell(i,1) = extractBetween(SWCFDC_arxml_Updated(location_P_CAN(i,1),1), '<SHORT-NAME>P_', '</SHORT-NAME>');
end

FINAL_CELL_CAN_TX = cell(amount_P_CAN,3);
for i = 1 : amount_P_CAN
    tmp_P_CAN_location = find(contains(CANX_cell,P_port_cell(i,1)), 1, 'first');
    FINAL_CELL_CAN_TX(i,:) = CANX_cell(tmp_P_CAN_location,:);
end

location_R_CAN = find(contains(SWCFDC_arxml_Updated,'<SHORT-NAME>R_CAN'));
amount_R_CAN = length(location_R_CAN);
R_port_cell = cell(amount_R_CAN,1);
for i = 1 : amount_R_CAN
    R_port_cell(i,1) = extractBetween(SWCFDC_arxml_Updated(location_R_CAN(i,1),1), '<SHORT-NAME>R_', '</SHORT-NAME>');
end

FINAL_CELL_CAN_RX = cell(amount_R_CAN,3);
for i = 1 : amount_R_CAN
    tmp_R_CAN_location = find(contains(CANX_cell,R_port_cell(i,1)), 1, 'first');
    FINAL_CELL_CAN_RX(i,:) = CANX_cell(tmp_R_CAN_location,:);
end

%% ------- Sort CAN Tx PDUs according to send type -------
%%% ------ Cycle Tx ------
amount_cell_CYCLE = intersect(find(contains(FINAL_CELL_CAN_TX(:, 3),'PENDING')), find(~contains(FINAL_CELL_CAN_TX(:, 2),'0.005')));
length_PENDING = length(amount_cell_CYCLE);
FINAL_CELL_CAN_TX_CYCLE = cell(length_PENDING, 3);

for i = 1 : length_PENDING
     FINAL_CELL_CAN_TX_CYCLE(i, :) = FINAL_CELL_CAN_TX(amount_cell_CYCLE(i,1), :);
end

FINAL_CELL_CAN_TX_CYCLE(:, 2) = cellfun(@(x) num2str(str2double(x) * 1000), FINAL_CELL_CAN_TX_CYCLE(:, 2), 'UniformOutput', false);
FINAL_CELL_CAN_TX_CYCLE = sortrows(FINAL_CELL_CAN_TX_CYCLE, 2);

FINAL_CELL_CAN_TX_CYCLE(:, end+1) = strcat('run_SWC_FDC_Tx_', FINAL_CELL_CAN_TX_CYCLE(:,2), 'ms');
FINAL_CELL_CAN_TX_CYCLE(:, end+1) = strcat('TE_', FINAL_CELL_CAN_TX_CYCLE(:,2), 'ms');
FINAL_CELL_CAN_TX_CYCLE(:, end+1) = strcat('P_', FINAL_CELL_CAN_TX_CYCLE(:, 1));
FINAL_CELL_CAN_TX_CYCLE(:, end+1) = regexprep(FINAL_CELL_CAN_TX_CYCLE(:, 1), 'CAN(\d+)_', ['CAN$1', '_SG_']);
FINAL_CELL_CAN_TX_CYCLE(:, end+1) = strcat('IRV_ms', FINAL_CELL_CAN_TX_CYCLE(:,2), '_', FINAL_CELL_CAN_TX_CYCLE(:, end));
FINAL_CELL_CAN_TX_CYCLE(:, end+1) = strcat('DT_', FINAL_CELL_CAN_TX_CYCLE(:, 7));
FINAL_CELL_CAN_TX_CYCLE(:, end+1) = strcat('/', extractBefore(FINAL_CELL_CAN_TX_CYCLE(:, 1), '_'), '/ImplementationDataTypes/', FINAL_CELL_CAN_TX_CYCLE(:, end));

index_TE10ms = ismember(FINAL_CELL_CAN_TX_CYCLE(:, 5), 'TE_10ms');
FINAL_CELL_CAN_TX_CYCLE_Only_10ms = FINAL_CELL_CAN_TX_CYCLE(index_TE10ms, :);
FINAL_CELL_CAN_TX_CYCLE_No_10ms = FINAL_CELL_CAN_TX_CYCLE(~index_TE10ms, :);

writetable(cell2table(FINAL_CELL_CAN_TX_CYCLE, 'VariableNames', {'Msg', 'Period', 'Type', 'Runnable', 'TimeEvent', 'Port', 'PortData', 'IRV', 'ImplType', 'ShortCut'}), 'testExcel.xls', 'sheet', 'Tx_Cycle');

allCAN_CycleUniquePeriods_cell = unique(FINAL_CELL_CAN_TX_CYCLE(:, 2));
allCAN_CycleTxRunnables_cell = cell(length(allCAN_CycleUniquePeriods_cell), 4);

allCAN_CycleUniquePeriods_No10ms_cell = unique(FINAL_CELL_CAN_TX_CYCLE_No_10ms(:, 2));
allCAN_CycleTxRunnables_No10ms_cell = cell(length(allCAN_CycleUniquePeriods_No10ms_cell), 4);

for i = 1 : length(allCAN_CycleUniquePeriods_cell)
     location_UniqueRunnable = find(strcmp(FINAL_CELL_CAN_TX_CYCLE(:, 2), allCAN_CycleUniquePeriods_cell(i)), 1, 'first');
     allCAN_CycleTxRunnables_cell(i, 1) = {location_UniqueRunnable};
     allCAN_CycleTxRunnables_cell(i, 2) = FINAL_CELL_CAN_TX_CYCLE(location_UniqueRunnable, 4);
     allCAN_CycleTxRunnables_cell(i, 3) = FINAL_CELL_CAN_TX_CYCLE(location_UniqueRunnable, 5);
     allCAN_CycleTxRunnables_cell(i, 4) = FINAL_CELL_CAN_TX_CYCLE(location_UniqueRunnable, 2);
end

for i = 1 : length(allCAN_CycleUniquePeriods_No10ms_cell)
     location_UniqueRunnable = find(strcmp(FINAL_CELL_CAN_TX_CYCLE_No_10ms(:, 2), allCAN_CycleUniquePeriods_No10ms_cell(i)), 1, 'first');
     allCAN_CycleTxRunnables_No10ms_cell(i, 1) = {location_UniqueRunnable};
     allCAN_CycleTxRunnables_No10ms_cell(i, 2) = FINAL_CELL_CAN_TX_CYCLE_No_10ms(location_UniqueRunnable, 4);
     allCAN_CycleTxRunnables_No10ms_cell(i, 3) = FINAL_CELL_CAN_TX_CYCLE_No_10ms(location_UniqueRunnable, 5);
     allCAN_CycleTxRunnables_No10ms_cell(i, 4) = FINAL_CELL_CAN_TX_CYCLE_No_10ms(location_UniqueRunnable, 2);
end
%%% ------ CE Tx ------
amount_cell_CE = union(find(contains(FINAL_CELL_CAN_TX(:, 3),'TRIGGERED-ON-CHANGE')), find(contains(FINAL_CELL_CAN_TX(:, 2),'0.005')));
length_TRIGGERED = length(amount_cell_CE);
FINAL_CELL_CAN_TX_CE = cell(length_TRIGGERED, 3);
for i = 1 : length_TRIGGERED
     FINAL_CELL_CAN_TX_CE(i, :) = FINAL_CELL_CAN_TX(amount_cell_CE(i,1), :);
end
FINAL_CELL_CAN_TX_CE(:, end+1) = strcat('P_', FINAL_CELL_CAN_TX_CE(:, 1));
FINAL_CELL_CAN_TX_CE(:, end+1) = regexprep(FINAL_CELL_CAN_TX_CE(:, 1), 'CAN(\d+)_', ['CAN$1', '_SG_']);

writetable(cell2table(FINAL_CELL_CAN_TX_CE, 'VariableNames', {'Msg', 'Period', 'Type', 'Port', 'PortData'}), 'testExcel.xls', 'sheet', 'Tx_CE');

%%% ------ Rx ------
FINAL_CELL_CAN_RX(:, end+1) = strcat('R_', FINAL_CELL_CAN_RX(:, 1));
FINAL_CELL_CAN_RX(:, end+1) = regexprep(FINAL_CELL_CAN_RX(:, 1), 'CAN(\d+)_', ['CAN$1', '_SG_']);
% FINAL_CELL_CAN_RX(:, end+1) = strcat('drparg_', FINAL_CELL_CAN_RX(1, end));
% FINAL_CELL_CAN_RX(:, end+1) = strcat('/SWC_FDC_ARPkg/SWC_FDC_type/', FINAL_CELL_CAN_RX(:, 5));
% FINAL_CELL_CAN_RX(:, end+1) = strcat('/CANInterface_ARPkg/IF_', FINAL_CELL_CAN_RX(:, 5), '/', FINAL_CELL_CAN_RX(:, 1));

% %% ------ Read original SWC_FDC.arxml ------
% fileID = fopen('SWC_FDC_ORIGINAL.arxml');
% SWCFDC_arxml_Updated = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
% fclose(fileID);
% SWCFDC_arxml_Updated = SWCFDC_arxml_Updated{1};

%% ------ Add IRVs to SWC_FDC.arxml ------
location_IRVs = find(contains(SWCFDC_arxml_Updated, '<EXPLICIT-INTER-RUNNABLE-VARIABLES>'), 1, 'first');
NewIRV_cell = cell(1,1);
for i = 1 : size(FINAL_CELL_CAN_TX_CYCLE,1)
    NewIRV_cell(end+1, 1) =       {'                <VARIABLE-DATA-PROTOTYPE>'};
    NewIRV_cell(end+1, 1) = strcat('                  <SHORT-NAME>', FINAL_CELL_CAN_TX_CYCLE(i, 8), '</SHORT-NAME>');
    NewIRV_cell(end+1, 1) = strcat('                  <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">', FINAL_CELL_CAN_TX_CYCLE(i, 10), '</TYPE-TREF>');
    NewIRV_cell(end+1, 1) =       {'                </VARIABLE-DATA-PROTOTYPE>'};
end
NewIRV_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_IRVs); NewIRV_cell; SWCFDC_arxml_Updated(location_IRVs+1:end)];

%% ------- Update Runnable for 10ms cycle Tx CAN in SWC_FDC.arxml-------
location_Tx10ms_runnable = find(contains(SWCFDC_arxml_Updated, '<SHORT-NAME>run_SWC_FDC_Tx_10ms</SHORT-NAME>'));
location_Data_Send_Points_10ms = location_Tx10ms_runnable + find(contains(SWCFDC_arxml_Updated(location_Tx10ms_runnable: end, 1), '<CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>'), 1, 'first') - 1;
NewCANTx10ms_cell = cell(1, 1);
NewCANTx10ms_cell(end+1, 1) = {'                  <DATA-SEND-POINTS>'};      
for i = 1 : size(FINAL_CELL_CAN_TX_CYCLE_Only_10ms, 1)
    NewCANTx10ms_cell(end+1, 1) =       {                    '<VARIABLE-ACCESS>'};
    NewCANTx10ms_cell(end+1, 1) = strcat('                      <SHORT-NAME>dsp_', FINAL_CELL_CAN_TX_CYCLE_Only_10ms(i, 7), '</SHORT-NAME>');
    NewCANTx10ms_cell(end+1, 1) =       {'                      <ACCESSED-VARIABLE>'};
    NewCANTx10ms_cell(end+1, 1) =       {'                        <AUTOSAR-VARIABLE-IREF>'};
    NewCANTx10ms_cell(end+1, 1) = strcat('                          <PORT-PROTOTYPE-REF DEST="P-PORT-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/', FINAL_CELL_CAN_TX_CYCLE_Only_10ms(i, 6), '</PORT-PROTOTYPE-REF>');
    NewCANTx10ms_cell(end+1, 1) = strcat('                          <TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">/CANInterface_ARPkg/IF_', FINAL_CELL_CAN_TX_CYCLE_Only_10ms(i, 7), '/', FINAL_CELL_CAN_TX_CYCLE_Only_10ms(i, 7), '</TARGET-DATA-PROTOTYPE-REF>');
    NewCANTx10ms_cell(end+1, 1) =       {'                        </AUTOSAR-VARIABLE-IREF>'};
    NewCANTx10ms_cell(end+1, 1) =       {'                      </ACCESSED-VARIABLE>'};
    NewCANTx10ms_cell(end+1, 1) =       {'                    </VARIABLE-ACCESS>'};    
end
NewCANTx10ms_cell(end+1, 1) = {'                  </DATA-SEND-POINTS>'};
NewCANTx10ms_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_Data_Send_Points_10ms); NewCANTx10ms_cell; SWCFDC_arxml_Updated(location_Data_Send_Points_10ms+1:end)];

location_Tx10ms_runnable = find(contains(SWCFDC_arxml_Updated, '<SHORT-NAME>run_SWC_FDC_Tx_10ms</SHORT-NAME>'));
location_Read_Local_Variables_10ms = location_Tx10ms_runnable + find(contains(SWCFDC_arxml_Updated(location_Tx10ms_runnable: end, 1), '<READ-LOCAL-VARIABLES>'), 1, 'first') - 1;
NewIRVRead10ms_cell = cell(1, 1);
for i = 1 : size(FINAL_CELL_CAN_TX_CYCLE_Only_10ms, 1)
    NewIRVRead10ms_cell(end+1, 1) =       {'                    <VARIABLE-ACCESS>'};
    NewIRVRead10ms_cell(end+1, 1) = strcat('                      <SHORT-NAME>', FINAL_CELL_CAN_TX_CYCLE_Only_10ms(i, 8), '</SHORT-NAME>');
    NewIRVRead10ms_cell(end+1, 1) =       {'                      <ACCESSED-VARIABLE>'};
    NewIRVRead10ms_cell(end+1, 1) = strcat('                        <LOCAL-VARIABLE-REF DEST="VARIABLE-DATA-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/SWC_FDC_type_IB/', FINAL_CELL_CAN_TX_CYCLE_Only_10ms(i, 8), '</LOCAL-VARIABLE-REF>');
    NewIRVRead10ms_cell(end+1, 1) =       {'                      </ACCESSED-VARIABLE>'};
    NewIRVRead10ms_cell(end+1, 1) =       {'                    </VARIABLE-ACCESS>'};    
end
NewIRVRead10ms_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_Read_Local_Variables_10ms); NewIRVRead10ms_cell; SWCFDC_arxml_Updated(location_Read_Local_Variables_10ms+1:end)];


%% ------- Add Runnable for Non-10ms cycle Tx CAN in SWC_FDC.arxml -------
%%% ------ Use allCAN_CycleTxRunnables_No10ms_cell as a database indexer to re-write
%%% SWC_FDC. arxml ------

%%% ------ Add runnable according to Tx PDU send type and period ------
location_Runnables = find(contains(SWCFDC_arxml_Updated, '<RUNNABLES>'), 1, 'first');
NewRunnable_cell = cell(1, 1);

for i = 1 : size(allCAN_CycleTxRunnables_No10ms_cell,1)
    NewRunnable_cell(end+1, 1) =       {'                <RUNNABLE-ENTITY>'};
    NewRunnable_cell(end+1, 1) = strcat('                  <SHORT-NAME>', allCAN_CycleTxRunnables_No10ms_cell(i, 2), '</SHORT-NAME>');
    NewRunnable_cell(end+1, 1) =       {'                  <CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>'};
    NewRunnable_cell(end+1, 1) =       {'                  <DATA-SEND-POINTS>'};
    index_start = cell2mat(allCAN_CycleTxRunnables_No10ms_cell(i, 1));

    if (index_start == cell2mat(allCAN_CycleTxRunnables_No10ms_cell(end, 1)))
        index_end = index_start;
    else
        index_end = cell2mat(allCAN_CycleTxRunnables_No10ms_cell(i+1, 1))-1;
    end

    for k = index_start : index_end
        NewRunnable_cell(end+1, 1) =       {'                    <VARIABLE-ACCESS>'};
        NewRunnable_cell(end+1, 1) = strcat('                      <SHORT-NAME>dsp_', FINAL_CELL_CAN_TX_CYCLE_No_10ms(k, 7), '</SHORT-NAME>');
        NewRunnable_cell(end+1, 1) =       {'                      <ACCESSED-VARIABLE>'};
        NewRunnable_cell(end+1, 1) =       {'                        <AUTOSAR-VARIABLE-IREF>'};
        NewRunnable_cell(end+1, 1) = strcat('                          <PORT-PROTOTYPE-REF DEST="P-PORT-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/', FINAL_CELL_CAN_TX_CYCLE_No_10ms(k, 6), '</PORT-PROTOTYPE-REF>');
        NewRunnable_cell(end+1, 1) = strcat('                          <TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">/CANInterface_ARPkg/IF_', FINAL_CELL_CAN_TX_CYCLE_No_10ms(k, 7), '/', FINAL_CELL_CAN_TX_CYCLE_No_10ms(k, 7), '</TARGET-DATA-PROTOTYPE-REF>');
        NewRunnable_cell(end+1, 1) =       {'                        </AUTOSAR-VARIABLE-IREF>'};
        NewRunnable_cell(end+1, 1) =       {'                      </ACCESSED-VARIABLE>'};
        NewRunnable_cell(end+1, 1) =       {'                    </VARIABLE-ACCESS>'};
    end

    NewRunnable_cell(end+1, 1) =       {'                  </DATA-SEND-POINTS>'};
    NewRunnable_cell(end+1, 1) =       {'                  <READ-LOCAL-VARIABLES>'};

    for y = index_start : index_end
        NewRunnable_cell(end+1, 1) =       {'                    <VARIABLE-ACCESS>'};
        NewRunnable_cell(end+1, 1) = strcat('                      <SHORT-NAME>', FINAL_CELL_CAN_TX_CYCLE_No_10ms(y, 8), '</SHORT-NAME>');
        NewRunnable_cell(end+1, 1) =       {'                      <ACCESSED-VARIABLE>'};
        NewRunnable_cell(end+1, 1) = strcat('                        <LOCAL-VARIABLE-REF DEST="VARIABLE-DATA-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/SWC_FDC_type_IB/', FINAL_CELL_CAN_TX_CYCLE_No_10ms(y, 8), '</LOCAL-VARIABLE-REF>');
        NewRunnable_cell(end+1, 1) =       {'                      </ACCESSED-VARIABLE>'};
        NewRunnable_cell(end+1, 1) =       {'                    </VARIABLE-ACCESS>'};
    end

    NewRunnable_cell(end+1, 1) =       {'                  </READ-LOCAL-VARIABLES>'};
    NewRunnable_cell(end+1, 1) = strcat('                  <SYMBOL>', allCAN_CycleTxRunnables_No10ms_cell(i, 2), '</SYMBOL>');
    NewRunnable_cell(end+1, 1) =       {'                </RUNNABLE-ENTITY>'};
end

NewRunnable_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_Runnables); NewRunnable_cell; SWCFDC_arxml_Updated(location_Runnables+1:end)];

%%% ------ Add time event for each Tx runnable according to Tx period ------
location_Events = find(contains(SWCFDC_arxml_Updated, '<EVENTS>'), 1, 'first');
NewTimeEvent_cell = cell(1, 1);
for i = 1 : size(allCAN_CycleTxRunnables_No10ms_cell, 1)
    NewTimeEvent_cell(end+1, 1) =       {'                <TIMING-EVENT>'};
    NewTimeEvent_cell(end+1, 1) = strcat('                  <SHORT-NAME>', allCAN_CycleTxRunnables_No10ms_cell(i, 3), '</SHORT-NAME>');
    NewTimeEvent_cell(end+1, 1) = strcat('                  <START-ON-EVENT-REF DEST="RUNNABLE-ENTITY">/SWC_FDC_ARPkg/SWC_FDC_type/SWC_FDC_type_IB/', allCAN_CycleTxRunnables_No10ms_cell(i, 2), '</START-ON-EVENT-REF>');
    NewTimeEvent_cell(end+1, 1) = strcat('                  <PERIOD>', cellfun(@(x) num2str(str2double(x) / 1000), allCAN_CycleTxRunnables_No10ms_cell(i, 4), 'UniformOutput', false), '</PERIOD>');
    NewTimeEvent_cell(end+1, 1) =       {'                </TIMING-EVENT>'};
end
NewTimeEvent_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_Events); NewTimeEvent_cell; SWCFDC_arxml_Updated(location_Events+1:end)];

%% ------- Re-write SWC_FDC.arxml for 5ms Rx and CE CAN Tx Runnable -------
%%% ------ Add CAN Rx data aaccess ------
location_5ms_Runnable = find(contains(SWCFDC_arxml_Updated, '<SHORT-NAME>run_SWC_FDC_RxTx_5ms</SHORT-NAME>'), 1, 'first');
location_Data_Receive_Point = location_5ms_Runnable + find(contains(SWCFDC_arxml_Updated(location_5ms_Runnable:end, 1), '<CAN-BE-INVOKED-CONCURRENTLY>'), 1, 'first') - 1;
NewCANRx5ms_cell = cell(1, 1);
NewCANRx5ms_cell(end+1, 1) =       {'                  <DATA-RECEIVE-POINT-BY-ARGUMENTS>'};
for i = 1 : size(FINAL_CELL_CAN_RX, 1)
    NewCANRx5ms_cell(end+1, 1) =       {'                    <VARIABLE-ACCESS>'};
    NewCANRx5ms_cell(end+1, 1) = strcat('                      <SHORT-NAME>drparg_', FINAL_CELL_CAN_RX(i, 5), '</SHORT-NAME>');
    NewCANRx5ms_cell(end+1, 1) =       {'                      <ACCESSED-VARIABLE>'};
    NewCANRx5ms_cell(end+1, 1) =       {'                        <AUTOSAR-VARIABLE-IREF>'};
    NewCANRx5ms_cell(end+1, 1) = strcat('                          <PORT-PROTOTYPE-REF DEST="R-PORT-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/', FINAL_CELL_CAN_RX(i, 4), '</PORT-PROTOTYPE-REF>');
    NewCANRx5ms_cell(end+1, 1) = strcat('                          <TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">/CANInterface_ARPkg/IF_', FINAL_CELL_CAN_RX(i, 5), '/', FINAL_CELL_CAN_RX(i, 5), '</TARGET-DATA-PROTOTYPE-REF>');
    NewCANRx5ms_cell(end+1, 1) =       {'                        </AUTOSAR-VARIABLE-IREF>'};
    NewCANRx5ms_cell(end+1, 1) =       {'                      </ACCESSED-VARIABLE>'};
    NewCANRx5ms_cell(end+1, 1) =       {'                    </VARIABLE-ACCESS>'};
end
NewCANRx5ms_cell(end+1, 1) =       {'                  </DATA-RECEIVE-POINT-BY-ARGUMENTS>'};
NewCANRx5ms_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_Data_Receive_Point); NewCANRx5ms_cell; SWCFDC_arxml_Updated(location_Data_Receive_Point+1:end)];

%%% ------ Add CAN Tx data aaccess ------
location_Data_Send_Point = location_5ms_Runnable +  find(contains(SWCFDC_arxml_Updated(location_5ms_Runnable:end, 1), '</DATA-RECEIVE-POINT-BY-ARGUMENTS>'), 1, 'first') - 1;
NewCANTx5ms_cell = cell(1, 1);
NewCANTx5ms_cell(end+1, 1) =       {'                  <DATA-SEND-POINTS>'};
for i = 1 : size(FINAL_CELL_CAN_TX_CE, 1)
    NewCANTx5ms_cell(end+1, 1) =       {'                    <VARIABLE-ACCESS>'};
    NewCANTx5ms_cell(end+1, 1) = strcat('                      <SHORT-NAME>dsp_', FINAL_CELL_CAN_TX_CE(i, 5), '</SHORT-NAME>');    
    NewCANTx5ms_cell(end+1, 1) =       {'                      <ACCESSED-VARIABLE>'};
    NewCANTx5ms_cell(end+1, 1) =       {'                        <AUTOSAR-VARIABLE-IREF>'};
    NewCANTx5ms_cell(end+1, 1) = strcat('                          <PORT-PROTOTYPE-REF DEST="P-PORT-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/', FINAL_CELL_CAN_TX_CE(i, 4), '</PORT-PROTOTYPE-REF>');
    NewCANTx5ms_cell(end+1, 1) = strcat('                          <TARGET-DATA-PROTOTYPE-REF DEST="VARIABLE-DATA-PROTOTYPE">/CANInterface_ARPkg/IF_', FINAL_CELL_CAN_TX_CE(i, 5), '/', FINAL_CELL_CAN_TX_CE(i, 5), '</TARGET-DATA-PROTOTYPE-REF>');
    NewCANTx5ms_cell(end+1, 1) =       {'                        </AUTOSAR-VARIABLE-IREF>'};
    NewCANTx5ms_cell(end+1, 1) =       {'                      </ACCESSED-VARIABLE>'};
    NewCANTx5ms_cell(end+1, 1) =       {'                    </VARIABLE-ACCESS>'};
end
NewCANTx5ms_cell(end+1, 1) =       {'                  </DATA-SEND-POINTS>'};
NewCANTx5ms_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_Data_Send_Point); NewCANTx5ms_cell; SWCFDC_arxml_Updated(location_Data_Send_Point+1:end)];
                        
%%% ------ Add IRV write ------
location_Write_Local_Variables = location_5ms_Runnable +  find(contains(SWCFDC_arxml_Updated(location_5ms_Runnable:end, 1), '<WRITTEN-LOCAL-VARIABLES>'), 1, 'first') - 1;
NewIRVwrite_cell = cell(1, 1);
for i = 1 : size(FINAL_CELL_CAN_TX_CYCLE, 1)
    NewIRVwrite_cell(end+1, 1) =       {'                    <VARIABLE-ACCESS>'};
    NewIRVwrite_cell(end+1, 1) = strcat('                      <SHORT-NAME>', FINAL_CELL_CAN_TX_CYCLE(i, 8), '</SHORT-NAME>');
    NewIRVwrite_cell(end+1, 1) =       {'                      <ACCESSED-VARIABLE>'};
    NewIRVwrite_cell(end+1, 1) = strcat('                        <LOCAL-VARIABLE-REF DEST="VARIABLE-DATA-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/SWC_FDC_type_IB/', FINAL_CELL_CAN_TX_CYCLE(i, 8), '</LOCAL-VARIABLE-REF>');
    NewIRVwrite_cell(end+1, 1) =       {'                      </ACCESSED-VARIABLE>'};    
    NewIRVwrite_cell(end+1, 1) =       {'                    </VARIABLE-ACCESS>'};
end
NewIRVwrite_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_Write_Local_Variables); NewIRVwrite_cell; SWCFDC_arxml_Updated(location_Write_Local_Variables + 1 : end)];


%% ----- DID -----
%%% ----- Delete original DIDList section -----

location_CSOP_DID_start = min(find(contains(SWCFDC_arxml_Updated, '<SHORT-NAME>scp_CSOP_DIDGet', 'IgnoreCase', false), 1, 'first') - 1, ...
    find(contains(SWCFDC_arxml_Updated, '<SHORT-NAME>scp_CSOP_DIDSet', 'IgnoreCase', false), 1, 'first') - 1);
location_CSOP_DID_end = max(find(contains(SWCFDC_arxml_Updated, '<SHORT-NAME>scp_CSOP_DIDGet', 'IgnoreCase', false), 1, 'last') + 6, ...
    find(contains(SWCFDC_arxml_Updated, '<SHORT-NAME>scp_CSOP_DIDSet', 'IgnoreCase', false), 1, 'last') + 6);
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_CSOP_DID_start - 1); SWCFDC_arxml_Updated(location_CSOP_DID_end + 1:end)];

%%% ----- Read FVT_DIDList -----
cd .. % /documents
FVT_DIDList = (readcell('FVT_DIDList.xlsx'));
DIDList_ArgDatatype = FVT_DIDList(3:end,4);
DIDList_RWMode = FVT_DIDList(3:end,6);
DIDList_SubDataName = FVT_DIDList(3:end,7);
DIDList_CSOPName = FVT_DIDList(3:end,8);
DIDList_DIDlen = FVT_DIDList(3:end,9);      % Input1
DIDList_DIDNum = FVT_DIDList(3:end,10);     % Input2
DIDList_DIDSta = FVT_DIDList(3:end,11);     % Output1
DIDList_VarNameIn = FVT_DIDList(3:end,12);  % Input3
DIDList_VarNameOut = FVT_DIDList(3:end,13); % Output2

%%% ------ Add DID SERVER-CALL-POINT ------
location_5ms_Runnable_start = find(contains(SWCFDC_arxml_Updated, '<SHORT-NAME>run_SWC_FDC_RxTx_5ms</SHORT-NAME>'), 1, 'first');
location_5ms_Runnable_end = find(contains(SWCFDC_arxml_Updated, '<SYMBOL>run_SWC_FDC_RxTx_5ms</SYMBOL>'), 1, 'first');
location_Data_Receive_Point = location_5ms_Runnable_start + find(contains(SWCFDC_arxml_Updated(location_5ms_Runnable_start:location_5ms_Runnable_end, 1), '<SYNCHRONOUS-SERVER-CALL-POINT>'), 1, 'last') - 2;
NewDIDRxTx5ms_cell = cell(1, 1);
for i = 1 : size(DIDList_CSOPName, 1)
    NewDIDRxTx5ms_cell(end+1, 1) =       {'                    <SYNCHRONOUS-SERVER-CALL-POINT>'};
    NewDIDRxTx5ms_cell(end+1, 1) = strcat('                      <SHORT-NAME>scp_', DIDList_CSOPName(i), '</SHORT-NAME>');
    NewDIDRxTx5ms_cell(end+1, 1) =       {'                      <OPERATION-IREF>'};
    if string(DIDList_RWMode(i)) == 'W'
        NewDIDRxTx5ms_cell(end+1, 1) =       {'                        <CONTEXT-R-PORT-REF DEST="R-PORT-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/R_DIDReadCDD</CONTEXT-R-PORT-REF>'};
        NewDIDRxTx5ms_cell(end+1, 1) = strcat('                        <TARGET-REQUIRED-OPERATION-REF DEST="CLIENT-SERVER-OPERATION">/Interface_DID_ARPkg/IF_DIDReadCDD/', DIDList_CSOPName(i), '</TARGET-REQUIRED-OPERATION-REF>');
    else % string(DIDList_RWMode(i)) == 'R'
        NewDIDRxTx5ms_cell(end+1, 1) =       {'                        <CONTEXT-R-PORT-REF DEST="R-PORT-PROTOTYPE">/SWC_FDC_ARPkg/SWC_FDC_type/R_DIDWriteCDD</CONTEXT-R-PORT-REF>'};
        NewDIDRxTx5ms_cell(end+1, 1) = strcat('                        <TARGET-REQUIRED-OPERATION-REF DEST="CLIENT-SERVER-OPERATION">/Interface_DID_ARPkg/IF_DIDWriteCDD/', DIDList_CSOPName(i), '</TARGET-REQUIRED-OPERATION-REF>');
    end
    NewDIDRxTx5ms_cell(end+1, 1) =       {'                      </OPERATION-IREF>'};
    NewDIDRxTx5ms_cell(end+1, 1) =       {'                      <TIMEOUT>0.0</TIMEOUT>'};
    NewDIDRxTx5ms_cell(end+1, 1) =       {'                    </SYNCHRONOUS-SERVER-CALL-POINT>'};
end
NewDIDRxTx5ms_cell(1, :) = [];
SWCFDC_arxml_Updated = [SWCFDC_arxml_Updated(1:location_Data_Receive_Point); NewDIDRxTx5ms_cell; SWCFDC_arxml_Updated(location_Data_Receive_Point+1:end)];


%% ------- Re-write SWC_FDC.arxml -------
cd ../documents/ARXML_output/
fileID = fopen( 'SWC_FDC.arxml','w');
for i = 1:length(SWCFDC_arxml_Updated(:,1))
    fprintf(fileID,'%s\n',char(SWCFDC_arxml_Updated(i,1)));
end
fclose(fileID);
%% ------ Move original SWC_FDC.arxml file to backup place ------
% movefile( 'SWC_FDC_ORIGINAL.arxml', '../../../../SWC_FDC_ORIGINAL.arxml');
delete('SWC_FDC_ORIGINAL.arxml')
