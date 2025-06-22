library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axi4_lite_slave_if is
    generic(C_AXI_ADDRESS_WIDTH: integer range 1 to 128 := 4;
            C_AXI_DATA_WIDTH: integer range 32 to 128 := 32;
            C_NUM_REGISTERS: integer range 1 to 1024 := 4);
    port(S_AXI_ACLK: in std_logic;
         S_AXI_ARESETN: in std_logic;
         S_AXI_AWADDR: in std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
         S_AXI_AWPROT: in std_logic_vector(2 downto 0);
         S_AXI_AWVALID: in std_logic;
         S_AXI_AWREADY: out std_logic;
         S_AXI_WVALID: in std_logic;
         S_AXI_WREADY: out std_logic;
         S_AXI_BRESP: out std_logic_vector(1 downto 0);
         S_AXI_BVALID: out std_logic;
         S_AXI_BREADY: in std_logic;
         S_AXI_ARADDR: in std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
         S_AXI_ARPROT: in std_logic_vector(2 downto 0);
         S_AXI_ARVALID: in std_logic;
         S_AXI_ARREADY: out std_logic;
         S_AXI_RRESP: out std_logic_vector(1 downto 0);
         S_AXI_RVALID: out std_logic;
         S_AXI_RREADY: out std_logic;

         REGISTER_WR: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0);
         REGISTER_RD: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0));
end axi4_lite_slave_if;

architecture synth_logic of axi4_lite_slave_if is
    type read_statemachine_type is (IDLE, ADDRESS_LATCH, DATA_OUT, ERROR_NOTIFY);
    type write_statemachine_type is (IDLE, ADDRESS_LATCH, DATA_IN, RESP_OUT, ERROR_NOTIFY);

    constant OKAY: std_logic_vector(1 downto 0) := "00";
    constant EXOKAY: std_logic_vector(1 downto 0) := "01";
    constant SLVERR: std_logic_vector(1 downto 0) := "10";
    constant DECERR: std_logic_vector(1 downto 0) := "11";
    constant ADDR_LSB: integer := (C_AXI_ADDRESS_WIDTH / 32) + 1;

    signal read_cstate: read_statemachine_type := IDLE;
    signal axi_arready: std_logic := '0';
    signal axi_rresp: std_logic_vector(S_AXI_RRESP'range) := OKAY;
    signal axi_rvalid: std_logic := '0';

    signal read_wire: std_logic := '0';
    signal read_address: unsigned(integer(ceil(log2(real(C_NUM_REGISTERS)))) - 1 downto 0) := (others => '0');
    
begin
    S_AXI_ARREADY <= axi_arready;
    S_AXI_RRESP <= axi_rresp;
    S_AXI_RVALID <= axi_rvalid;

    read_process: process(S_AXI_ACLK) is
    begin
        if(rising_edge(S_AXI_ACLK)) then
            if(S_AXI_ARESETN = '0') then
                axi_arready <= '0';
                read_wire <= '0';
                read_address <= (others => '0');
                read_cstate <= IDLE;
            else
                case read_cstate is
                    when IDLE =>
                        axi_rvalid <= '0';
                        axi_rvalid <= '0';
                        if(S_AXI_ARVALID = '1') then
                            read_cstate <= ADDRESS_LATCH;
                        else
                            read_cstate <= IDLE;
                        end if;
                    when ADDRESS_LATCH =>
                        axi_arready <= '1';
                        read_wire <= '1';
                        read_address <= unsigned(S_AXI_ARADDR(C_AXI_ADDRESS_WIDTH - 1 downto ADDR_LSB));
                        if(read_address < C_NUM_REGISTERS) then
                            read_cstate <= DATA_OUT;
                        else
                            read_cstate <= ERROR_NOTIFY;
                        end if;
                    when DATA_OUT =>
                        axi_arready <= '0';
                        read_wire <= '0';
                        axi_rvalid <= '1';
                        if(S_AXI_RREADY = '1') then
                            read_cstate <= IDLE;
                        else
                            read_cstate <= DATA_OUT;
                        end if;
                    when ERROR_NOTIFY =>
                        axi_arready <= '0';
                        axi_rvalid <= '1';
                        axi_rresp <= DECERR;
                        if(S_AXI_RREADY = '1') then
                            read_cstate <= IDLE;
                        else
                            read_cstate <= ERROR_NOTIFY;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process read_process;

    read_strobe_proc: process(S_AXI_ACLK) is
    begin
        if(rising_edge(S_AXI_ACLK)) then
            if(read_wire = '1') then
                for idx in 0 to C_NUM_REGISTERS - 1 loop
                    if(idx = to_integer(read_address)) then
                        REGISTER_RD(idx) <= '1';
                    end if;
                end loop;
            end if;
        end if;
    end process read_strobe_proc;

end synth_logic;
