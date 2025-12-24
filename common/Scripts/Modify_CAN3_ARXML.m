function Modify_CAN3_ARXML(project_path)

cd ../documents/ARXML_output/
fileID = fopen('CAN3.arxml');
CAN3_arxml = textscan(fileID,'%s', 'delimiter', '\n', 'whitespace', '');
fclose(fileID);
CAN3_arxml = CAN3_arxml{1};

% FD3_VCU1
location_FD3_VCU1 = find(contains(CAN3_arxml, '              <SYSTEM-SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">/CAN3/SignalGroup/CAN3_SG_FD3_VCU0</SYSTEM-SIGNAL-GROUP-REF>'), 1, 'first') + 3;
FD3_VCU1_cell = cell(1,1);

FD3_VCU1_cell(end+1, 1) =       {'			  <COM-BASED-SIGNAL-GROUP-TRANSFORMATIONS>'};
FD3_VCU1_cell(end+1, 1) =       {'                <DATA-TRANSFORMATION-REF-CONDITIONAL>'};
FD3_VCU1_cell(end+1, 1) =       {'                  <DATA-TRANSFORMATION-REF DEST="DATA-TRANSFORMATION">/DataTransformations/DataTransformationSet/E2E_PROFILE_01_CAN3_SG_FD3_VCU1</DATA-TRANSFORMATION-REF>'};
FD3_VCU1_cell(end+1, 1) =       {'                </DATA-TRANSFORMATION-REF-CONDITIONAL>'};
FD3_VCU1_cell(end+1, 1) =       {'              </COM-BASED-SIGNAL-GROUP-TRANSFORMATIONS>'};

FD3_VCU1_cell(1, :) = [];
CAN3_arxml = [CAN3_arxml(1:location_FD3_VCU1); FD3_VCU1_cell; CAN3_arxml(location_FD3_VCU1+1:end)];


location_FD3_VCU1 = find(contains(CAN3_arxml, '              <SYSTEM-SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">/CAN3/SignalGroup/CAN3_SG_FD3_VCU1</SYSTEM-SIGNAL-GROUP-REF>'), 1, 'first');
FD3_VCU1_cell = cell(1,1);

FD3_VCU1_cell(end+1, 1) =       {'			  <TRANSFORMATION-I-SIGNAL-PROPSS>'};
FD3_VCU1_cell(end+1, 1) =       {'                <END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS>'};
FD3_VCU1_cell(end+1, 1) =       {'                  <END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS-VARIANTS>'};
FD3_VCU1_cell(end+1, 1) =       {'                    <END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS-CONDITIONAL>'};
FD3_VCU1_cell(end+1, 1) =       {'                      <TRANSFORMER-REF DEST="TRANSFORMATION-TECHNOLOGY">/DataTransformations/DataTransformationSet/Technology_E2E_PROFILE_01_CAN3_SG_FD3_VCU1</TRANSFORMER-REF>'};
FD3_VCU1_cell(end+1, 1) =       {'                      <DATA-IDS>'};
FD3_VCU1_cell(end+1, 1) =       {'                        <DATA-ID>17910</DATA-ID>'};
FD3_VCU1_cell(end+1, 1) =       {'                      </DATA-IDS>'};
FD3_VCU1_cell(end+1, 1) =       {'                      <DATA-LENGTH>64</DATA-LENGTH>'};
FD3_VCU1_cell(end+1, 1) =       {'                    </END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS-CONDITIONAL>'};
FD3_VCU1_cell(end+1, 1) =       {'                  </END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS-VARIANTS>'};
FD3_VCU1_cell(end+1, 1) =       {'                </END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS>'};
FD3_VCU1_cell(end+1, 1) =       {'              </TRANSFORMATION-I-SIGNAL-PROPSS>'};

FD3_VCU1_cell(1, :) = [];
CAN3_arxml = [CAN3_arxml(1:location_FD3_VCU1); FD3_VCU1_cell; CAN3_arxml(location_FD3_VCU1+1:end)];


% FD3_VCU1_toNIDEC

location_FD3_VCU1_toNIDEC = find(contains(CAN3_arxml, '              <SYSTEM-SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">/CAN3/SignalGroup/CAN3_SG_FD3_VCU1</SYSTEM-SIGNAL-GROUP-REF>'), 1, 'first') + 16;
FD3_VCU1_toNIDEC_cell = cell(1,1);

FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'			  <COM-BASED-SIGNAL-GROUP-TRANSFORMATIONS>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                <DATA-TRANSFORMATION-REF-CONDITIONAL>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                  <DATA-TRANSFORMATION-REF DEST="DATA-TRANSFORMATION">/DataTransformations/DataTransformationSet/E2E_PROFILE_01_CAN3_SG_FD3_VCU1_toNIDEC</DATA-TRANSFORMATION-REF>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                </DATA-TRANSFORMATION-REF-CONDITIONAL>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'              </COM-BASED-SIGNAL-GROUP-TRANSFORMATIONS>'};

FD3_VCU1_toNIDEC_cell(1, :) = [];
CAN3_arxml = [CAN3_arxml(1:location_FD3_VCU1_toNIDEC); FD3_VCU1_toNIDEC_cell; CAN3_arxml(location_FD3_VCU1_toNIDEC+1:end)];


location_FD3_VCU1_toNIDEC = find(contains(CAN3_arxml, '              <SYSTEM-SIGNAL-GROUP-REF DEST="SYSTEM-SIGNAL-GROUP">/CAN3/SignalGroup/CAN3_SG_FD3_VCU1_toNIDEC</SYSTEM-SIGNAL-GROUP-REF>'), 1, 'first');
FD3_VCU1_toNIDEC_cell = cell(1,1);

FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'			  <TRANSFORMATION-I-SIGNAL-PROPSS>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                <END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                  <END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS-VARIANTS>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                    <END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS-CONDITIONAL>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                      <TRANSFORMER-REF DEST="TRANSFORMATION-TECHNOLOGY">/DataTransformations/DataTransformationSet/Technology_E2E_PROFILE_01_CAN3_SG_FD3_VCU1_toNIDEC</TRANSFORMER-REF>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                      <DATA-IDS>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                        <DATA-ID>13815</DATA-ID>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                      </DATA-IDS>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                      <DATA-LENGTH>64</DATA-LENGTH>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                    </END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS-CONDITIONAL>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                  </END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS-VARIANTS>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'                </END-TO-END-TRANSFORMATION-I-SIGNAL-PROPS>'};
FD3_VCU1_toNIDEC_cell(end+1, 1) =       {'              </TRANSFORMATION-I-SIGNAL-PROPSS>'};

FD3_VCU1_toNIDEC_cell(1, :) = [];
CAN3_arxml = [CAN3_arxml(1:location_FD3_VCU1_toNIDEC); FD3_VCU1_toNIDEC_cell; CAN3_arxml(location_FD3_VCU1_toNIDEC+1:end)];


%% Output Target_arxml
cd([project_path '/documents/ARXML_output'])
fileID = fopen( 'CAN3.arxml','w');
for i = 1:length(CAN3_arxml(:,1))
    fprintf(fileID,'%s\n',char(CAN3_arxml(i,1)));
end
fclose(fileID);

end