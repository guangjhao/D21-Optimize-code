import re, time, os, shutil

def modify_sendtype(dbc_file_path, message_name, new_genmsgsendtype, new_gensigsendtype):
    
    with open(dbc_file_path, 'r') as file:
        lines = file.readlines()

    message_regex = re.compile(r'BO_ (\d+) (\w+)')
    signal_regex = re.compile(r' SG_ (\w+) ')
    genmsgsendtype_regex = re.compile(r'\s*BA_ "GenMsgSendType" BO_ (\d+) (\d+);')
    gensigsendtype_regex = re.compile(r'\s*BA_ "GenSigSendType" SG_ (\d+) (\w+) (\d+);')

    
    # Find Message ID and Signals
    signal_array = []
    in_target_message = False
    for i, line in enumerate(lines):
        message_match = message_regex.match(line)
        if message_match:
            if message_match.group(2) == message_name:
                target_message_id = message_match.group(1)
                in_target_message = True
            else:
                in_target_message = False
            
        if in_target_message:
            signal_match = signal_regex.search(line)
            if signal_match:
                signal_array.append(signal_match.group(1))
    
    
    # Modify GenMsgSendType    
    for i, line in enumerate(lines):        
        genmsgsendtype_match = genmsgsendtype_regex.match(line)
        if genmsgsendtype_match and genmsgsendtype_match.group(1) == target_message_id:
            lines[i] = f'BA_ "GenMsgSendType" BO_ {genmsgsendtype_match.group(1)} {new_genmsgsendtype};\n'


    # Modify GenSigSendType
    for i, line in enumerate(lines):        
        gensigsendtype_match = gensigsendtype_regex.match(line)
        if gensigsendtype_match and gensigsendtype_match.group(1) == target_message_id:
            lines[i] = f'BA_ "GenSigSendType" SG_ {gensigsendtype_match.group(1)} {gensigsendtype_match.group(2)} {new_gensigsendtype};\n'
            signal_array.remove(gensigsendtype_match.group(2))
    
    
    # Add GenSigSendType for undefined signals
    for i, line in enumerate(lines):        
        gensigsendtype_match = gensigsendtype_regex.match(line)
        if gensigsendtype_match and gensigsendtype_match.group(1) == target_message_id and signal_array:           
            for signal in signal_array:
                new_line = f'BA_ "GenSigSendType" SG_ {gensigsendtype_match.group(1)} {signal} {new_gensigsendtype};\n'
                lines.insert(i+1, new_line)
            break
    
    
    with open(dbc_file_path, 'w') as file:
        file.writelines(lines)

def modify_XNMm(dbc_file_path, message_name, new_genmsgcycletime):
    
    with open(dbc_file_path, 'r') as file:
        lines = file.readlines()

    message_regex = re.compile(r'BO_ (\d+) (\w+): (\d+) (\w+)')
    genmsgcycletype_regex = re.compile(r'\s*BA_ "GenMsgCycleTime" BO_ (\d+) (\d+);')
    
    # Modify XNMm
    for i, line in enumerate(lines):
        message_match = message_regex.match(line)
        if message_match and message_match.group(2) == message_name:
            lines[i] = f'BO_ {message_match.group(1)} X{message_match.group(2)}: {message_match.group(3)} {message_match.group(4)}\n'
            target_message_id = message_match.group(1)

    # Modify GenMsgCycleType    
    for i, line in enumerate(lines):        
        genmsgsendtype_match = genmsgcycletype_regex.match(line)
        if genmsgsendtype_match and genmsgsendtype_match.group(1) == target_message_id:
            lines[i] = f'BA_ "GenMsgCycleTime" BO_ {genmsgsendtype_match.group(1)} {new_genmsgcycletime};\n'
    
    with open(dbc_file_path, 'w') as file:
        file.writelines(lines)


def save_dbc_Workaround():
    current_dir = os.path.abspath(__file__)
    upper_dir = os.path.dirname(current_dir)
    parent_dir = os.path.dirname(upper_dir)
    CMM_WorkAround_folder_path = os.path.join(parent_dir, 'documents', 'MessageMap_AUTOSAR_WorkAround')
    
    all_files = os.listdir(CMM_WorkAround_folder_path)
    dbc_files = [file for file in all_files if file.endswith('.dbc')]
    
    for dbc_file_name in dbc_files:
        base_name, ext = os.path.splitext(dbc_file_name)
        new_dbc_file_name = base_name + '_AUTOSAR' + ext
        dbc_file = os.path.join(CMM_WorkAround_folder_path, dbc_file_name)
        new_dbc_file = os.path.join(CMM_WorkAround_folder_path, new_dbc_file_name)
        os.rename(dbc_file, new_dbc_file)
    
    all_files = os.listdir(CMM_WorkAround_folder_path)
    ini_files = [file for file in all_files if file.endswith('.ini')]
        
    for file_name in ini_files:
        full_file_name = os.path.join(CMM_WorkAround_folder_path, file_name)
        if os.path.isfile(full_file_name) or os.path.islink(full_file_name):
            os.unlink(full_file_name)
        elif os.path.isdir(full_file_name):
            shutil.rmtree(full_file_name)
            
    return CMM_WorkAround_folder_path 


def copy_dbc_Workaround():    
    current_dir = os.path.abspath(__file__)
    upper_dir = os.path.dirname(current_dir)
    parent_dir = os.path.dirname(upper_dir)
    dest_folder = os.path.join(parent_dir, 'documents', 'MessageMap_AUTOSAR_WorkAround')
    src_folder = os.path.join(parent_dir, 'documents', 'MessageMap')
    all_dest_files = os.listdir(dest_folder)
    all_src_files = os.listdir(src_folder)
    
    for file_name in all_dest_files:
        full_file_name = os.path.join(dest_folder, file_name)
        if os.path.isfile(full_file_name) or os.path.islink(full_file_name):
            os.unlink(full_file_name)
        elif os.path.isdir(full_file_name):
            shutil.rmtree(full_file_name)
    
    for file_name in all_src_files:
        full_file_name = os.path.join(src_folder, file_name)
        shutil.copy(full_file_name, dest_folder)


def get_dbc_file_names(CMM_WorkAround_folder_path):
    all_files = os.listdir(CMM_WorkAround_folder_path)
    dbc_files = [file for file in all_files if file.endswith('.dbc')]
    
    return dbc_files    


def find_and_modify_nmm_messages(dbc_file_path):
    with open(dbc_file_path, 'r') as file:
        lines = file.readlines()

    message_regex = re.compile(r'BO_ (\d+) (\w+): (\d+) (\w+)')
    
    for line in lines:
        message_match = message_regex.match(line)
        if message_match and 'NMm' in message_match.group(2):
            message_name = message_match.group(2)
            new_genmsgsendtype = '0' # 0: Cycle
            new_gensigsendtype = '0' # 0: Cycle
            new_genmsgcycletime = '700'  
            modify_sendtype(dbc_file_path, message_name, new_genmsgsendtype, new_gensigsendtype)
            modify_XNMm(dbc_file_path, message_name, new_genmsgcycletime) 



"""
1. Rename NMm message to XNMm.
2. Change all NM messages send type to cycle with 700ms cycle time.
3. Change all NM signals send type to cycle.
4. Change CAN3_VCU1 message send type to “Event” and signals send type to onWrite.
5. Change CAN4_VCU1 message send type to “Event” and signals send type to onWrite.
"""

if __name__ == "__main__":

    copy_dbc_Workaround()
    
    CMM_WorkAround_folder_path = save_dbc_Workaround()
    
    dbc_files = get_dbc_file_names(CMM_WorkAround_folder_path)
    
    for dbc_file in dbc_files:
        dbc_file_path = os.path.join(CMM_WorkAround_folder_path, dbc_file)
        
        if 'CAN3' in dbc_file:
            # dbc_file_path = os.path.join(CMM_WorkAround_folder_path, dbc_file)        
            new_genmsgsendtype = '3' # 3: Event 
            new_gensigsendtype = '1' # 1: Onwrite               
            message_name = 'FD_VCU1' 
            modify_sendtype(dbc_file_path, message_name, new_genmsgsendtype, new_gensigsendtype)            
        
        if 'CAN4' in dbc_file:
            # dbc_file_path = os.path.join(CMM_WorkAround_folder_path, dbc_file)
            new_genmsgsendtype = '3' # 3: Event
            new_gensigsendtype = '1' # 1: Onwrite               
            message_name = 'FD_VCU1'
            modify_sendtype(dbc_file_path, message_name, new_genmsgsendtype, new_gensigsendtype)     
        
        find_and_modify_nmm_messages(dbc_file_path)     
    
