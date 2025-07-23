library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axi4_lite_slave_if is
    generic(C_AXI_DATA_WIDTH: integer range 32 to 128 := 32;
            C_AXI_ADDRESS_WIDTH: integer range 4 to 128 := 4;
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
         S_AXI_RREADY: in std_logic;

         REGISTER_WR: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0);
         REGISTER_RD: out std_logic_vector(C_NUM_REGISTERS - 1 downto 0));
end axi4_lite_slave_if;

architecture synth_logic of axi4_lite_slave_if is
    type read_statemachine_type is (IDLE, ADDRESS_LATCH, DATA_OUT, ERROR_NOTIFY);
    type write_statemachine_type is (IDLE, ADDRESS_LATCH, WAIT_FOR_VALID, DATA_IN, RESPONSE_OUT, ERROR_NOTIFY);

    constant OKAY: std_logic_vector(1 downto 0) := "00";
    constant EXOKAY: std_logic_vector(1 downto 0) := "01";
    constant SLVERR: std_logic_vector(1 downto 0) := "10";
    constant DECERR: std_logic_vector(1 downto 0) := "11";
    constant ADDR_LSB: integer := (C_AXI_DATA_WIDTH / 32) + 1;

    signal read_cstate: read_statemachine_type := IDLE;
    signal axi_arready: std_logic := '0';
    signal axi_rresp: std_logic_vector(S_AXI_RRESP'range) := OKAY;
    signal axi_rvalid: std_logic := '0';
    signal read_reg: std_logic_vector(REGISTER_RD'range) := (others => '0');

    signal write_cstate: write_statemachine_type := IDLE;
    signal axi_awready: std_logic := '0';
    signal axi_wready: std_logic := '0';
    signal axi_bvalid: std_logic := '0';
    signal axi_bresp: std_logic_vector(S_AXI_BRESP'range) := OKAY;
    signal write_reg: std_logic_vector(REGISTER_WR'range) := (others => '0');

begin
    S_AXI_ARREADY <= axi_arready;
    S_AXI_RRESP <= axi_rresp;
    S_AXI_RVALID <= axi_rvalid;
    REGISTER_RD <= read_reg;

    S_AXI_AWREADY <= axi_awready;
    S_AXI_WREADY <= axi_wready;
    S_AXI_BVALID <= axi_bvalid;
    S_AXI_BRESP <= axi_bresp;
    REGISTER_WR <= write_reg;
                       
    read_process: process(S_AXI_ACLK) is
        variable read_address: unsigned(integer(ceil(log2(real(C_NUM_REGISTERS)))) - 1 downto 0) := (others => '0');
    begin
        if(rising_edge(S_AXI_ACLK)) then
            if(S_AXI_ARESETN = '0') then
                axi_arready <= '0';
                axi_rvalid <= '0';
                read_address := (others => '0');
                read_reg <= (others => '0');
                read_cstate <= IDLE;
                axi_rresp <= OKAY;
            else
                case read_cstate is
                    when IDLE =>
                        axi_rvalid <= '0';
                        read_reg <= (others => '0');
                        axi_rresp <= OKAY;
                        if(S_AXI_ARVALID = '1') then
                            read_cstate <= ADDRESS_LATCH;
                        else
                            read_cstate <= IDLE;
                        end if;
                    when ADDRESS_LATCH =>
                        axi_arready <= '1';
                        read_address := unsigned(S_AXI_ARADDR(S_AXI_ARADDR'high downto ADDR_LSB));
                        if(read_address < to_unsigned(C_NUM_REGISTERS, read_address'length)) then
                            for idx in read_reg'range loop
                                if(idx = to_integer(read_address)) then
                                    read_reg(idx) <= '1';
                                end if;
                            end loop;
                            read_cstate <= DATA_OUT;
                        else
                            read_cstate <= ERROR_NOTIFY;
                        end if;
                    when DATA_OUT =>
                        axi_arready <= '0';
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

    write_process: process(S_AXI_ACLK) is
        variable write_address: unsigned(integer(ceil(log2(real(C_NUM_REGISTERS)))) - 1 downto 0) := (others => '0');
    begin
        if(rising_edge(S_AXI_ACLK)) then
            if(S_AXI_ARESETN = '0') then
                write_cstate <= IDLE;
                axi_awready <= '0';
                axi_wready <= '0';
                axi_bvalid <= '0';
                axi_bresp <= OKAY;
                write_reg <= (others => '0');
                write_address := (others => '0');
            else
                case write_cstate is
                    when IDLE => 
                        axi_bvalid <= '0';
                        axi_bresp <= OKAY;
                        if(S_AXI_AWVALID = '1') then
                            write_cstate <= ADDRESS_LATCH;
                        else
                            write_cstate <= IDLE;
                        end if;
                    when ADDRESS_LATCH =>
                        axi_awready <= '1';
                        write_address := unsigned(S_AXI_AWADDR(S_AXI_AWADDR'high downto ADDR_LSB));
                        if(write_address < to_unsigned(C_NUM_REGISTERS, write_address'length)) then
                            for idx in write_reg'range loop
                                if(idx = to_integer(write_address)) then
                                    write_reg(idx) <= '1';
                                end if;
                            end loop;
                            write_cstate <= WAIT_FOR_VALID;
                        else
                            write_cstate <= ERROR_NOTIFY;
                        end if;
                    when WAIT_FOR_VALID =>
                        axi_awready <= '0';
                        if(S_AXI_WVALID = '1') then
	                        write_cstate <= DATA_IN;
                        else
                            write_cstate <= ADDRESS_LATCH;
                        end if;    
                    when DATA_IN =>
                        axi_wready <= '1';
                        write_cstate <= RESPONSE_OUT;
                    when RESPONSE_OUT =>
                        write_reg <= (others => '0');
                        axi_wready <= '0';
                        axi_bvalid <= '1';
                        axi_bresp <= OKAY;
                        if(S_AXI_BREADY = '1') then
                            write_cstate <= IDLE;
                        else
                            write_cstate <= RESPONSE_OUT;
                        end if;
                    when ERROR_NOTIFY =>
                        axi_awready <= '0';
                        axi_bvalid <= '1';
                        axi_bresp <= DECERR;
                        if(S_AXI_BREADY = '1') then
                            write_cstate <= IDLE;
                        else
                            write_cstate <= ERROR_NOTIFY;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process write_process;
end synth_logic;
