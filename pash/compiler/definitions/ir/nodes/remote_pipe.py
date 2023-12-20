from definitions.ir.dfg_node import *


class RemotePipe(DFGNode):
    def __init__(self, inputs, outputs, com_name, com_category,
                 com_options=[], com_redirs=[], com_assignments=[]):
        super().__init__(inputs, outputs, com_name, com_category,
                         com_options=com_options,
                         com_redirs=com_redirs,
                         com_assignments=com_assignments)

    def add_debug_flag(self):
        opt_count = len(self.com_options)
        self.com_options.append((opt_count, Arg(string_to_argument(f"-d"))))

    def is_remote_read(self):
        com_name = self.com_name.opt_serialize()
        read_com = config.config['runtime']['remote_read_binary']
        return read_com in com_name
    
    def get_host(self):
        for idx, option in enumerate(self.com_options):
            if "--addr" in option[1].opt_serialize():
                addr = option[1].opt_serialize().split(' ')[1]
                ip, port = addr.split(':')[0], addr.split(':')[1]
                return ip
        return None

    def set_addr(self, host_ip, port):
        for idx, option in enumerate(self.com_options):
            if "--addr" in option[1].opt_serialize():
                # Replace with new addr_option
                self.com_options[idx] = (idx, Arg(string_to_argument(f"--addr {host_ip}:{port}")))
                break

    def set_addr_conditional(self, host_ip, port, original_host_ip, original_port):
        # replace original_host_ip, original_port with new host_ip, port
        for idx, option in enumerate(self.com_options):
            if "--addr" in option[1].opt_serialize():
                addr = option[1].opt_serialize().split(' ')[1]
                if original_host_ip == addr.split(':')[0] and str(original_port) == addr.split(':')[1]:
                    self.com_options[idx] = (idx, Arg(string_to_argument(f"--addr {host_ip}:{port}")))



def make_remote_pipe(inputs, outputs, host_ip, port, is_remote_read, id):
    com_category = "pure"
    options = []
    opt_count = 0

    if is_remote_read:
        remote_pipe_bin = os.path.join(
            config.DISH_TOP, config.config['runtime']['remote_read_binary'])
    else:
        remote_pipe_bin = os.path.join(
            config.DISH_TOP, config.config['runtime']['remote_write_binary'])

    com_name = Arg(string_to_argument(remote_pipe_bin))

    options.append(
        (opt_count, Arg(string_to_argument(f"--addr {host_ip}:{port}"))))
    options.append((opt_count + 1, Arg(string_to_argument(f"--id {id}"))))

    return RemotePipe(inputs,
                      outputs,
                      com_name,
                      com_category,
                      com_options=options)
