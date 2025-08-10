library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity axi_testbench is
    generic(C_AXI_DATA_WIDTH: integer range 32 to 128 := 32;
            C_AXI_ADDRESS_WIDTH: integer range 4 to 128 := 4;
            C_NUM_REGISTERS: integer range 1 to 1024 := 6);
end axi_testbench;

architecture behavioral of axi_testbench is
    
    -- Helper function to convert std_logic_vector to hex string
    function to_hex_string(slv : std_logic_vector) return string is
        variable hex : string(1 to slv'length/4);
        variable temp : std_logic_vector(slv'length-1 downto 0) := slv;
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in hex'range loop
            nibble := temp(temp'left downto temp'left-3);
            case nibble is
                when "0000" => hex(i) := '0';
                when "0001" => hex(i) := '1';
                when "0010" => hex(i) := '2';
                when "0011" => hex(i) := '3';
                when "0100" => hex(i) := '4';
                when "0101" => hex(i) := '5';
                when "0110" => hex(i) := '6';
                when "0111" => hex(i) := '7';
                when "1000" => hex(i) := '8';
                when "1001" => hex(i) := '9';
                when "1010" => hex(i) := 'A';
                when "1011" => hex(i) := 'B';
                when "1100" => hex(i) := 'C';
                when "1101" => hex(i) := 'D';
                when "1110" => hex(i) := 'E';
                when "1111" => hex(i) := 'F';
                when others => hex(i) := 'X';
            end case;
            temp := temp(temp'left-4 downto 0) & "0000";
        end loop;
        return hex;
    end function;

    signal S_AXI_ACLK: std_logic := '0';
    signal S_AXI_ARESETN: std_logic := '0';
    signal S_AXI_AWADDR: std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
    signal S_AXI_AWPROT: std_logic_vector(2 downto 0) := (others => '0');
    signal S_AXI_AWVALID: std_logic := '0';
    signal S_AXI_AWREADY: std_logic := '0';
    signal S_AXI_WDATA: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal S_AXI_WSTRB: std_logic_vector((C_AXI_DATA_WIDTH / 8) - 1 downto 0) := (others => '0');
    signal S_AXI_WVALID: std_logic := '0';
    signal S_AXI_WREADY: std_logic := '0';
    signal S_AXI_BRESP: std_logic_vector(1 downto 0) := (others => '0');
    signal S_AXI_BVALID: std_logic := '0';
    signal S_AXI_BREADY: std_logic := '0';
    signal S_AXI_ARADDR: std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0) := (others => '0');
    signal S_AXI_ARPROT: std_logic_vector(2 downto 0) := (others => '0');
    signal S_AXI_ARVALID: std_logic := '0';
    signal S_AXI_ARREADY: std_logic := '0';
    signal S_AXI_RDATA: std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal S_AXI_RRESP: std_logic_vector(1 downto 0) := (others => '0');
    signal S_AXI_RVALID: std_logic := '0';
    signal S_AXI_RREADY: std_logic := '0';
begin
    S_AXI_ACLK <= not S_AXI_ACLK after 4 ns;
    S_AXI_ARESETN <= '1' after 1 us;

    MUT: entity work.AXI_FIFO generic map(C_AXI_DATA_WIDTH => C_AXI_DATA_WIDTH,
                                          C_AXI_ADDRESS_WIDTH => C_AXI_ADDRESS_WIDTH)
                              port map(S_AXI_ACLK => S_AXI_ACLK,
                                       S_AXI_ARESETN => S_AXI_ARESETN,
                                       S_AXI_AWADDR => S_AXI_AWADDR,
                                       S_AXI_AWPROT => S_AXI_AWPROT,
                                       S_AXI_AWVALID => S_AXI_AWVALID,
                                       S_AXI_AWREADY => S_AXI_AWREADY,
                                       S_AXI_WDATA => S_AXI_WDATA,
                                       S_AXI_WSTRB => S_AXI_WSTRB,
                                       S_AXI_WVALID => S_AXI_WVALID,
                                       S_AXI_WREADY => S_AXI_WREADY,
                                       S_AXI_BRESP => S_AXI_BRESP,
                                       S_AXI_BVALID => S_AXI_BVALID,
                                       S_AXI_BREADY => S_AXI_BREADY,
                                       S_AXI_ARADDR => S_AXI_ARADDR,
                                       S_AXI_ARPROT => S_AXI_ARPROT,
                                       S_AXI_ARVALID => S_AXI_ARVALID,
                                       S_AXI_ARREADY => S_AXI_ARREADY,
                                       S_AXI_RDATA => S_AXI_RDATA,
                                       S_AXI_RRESP => S_AXI_RRESP,
                                       S_AXI_RVALID => S_AXI_RVALID,
                                       S_AXI_RREADY => S_AXI_RREADY);

    -- AXI4-Lite Write Transaction Process
    axi_write_proc: process
        -- Procedure for AXI4-Lite Write Transaction
        procedure axi_write_transaction(
            constant addr : in std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
            constant data : in std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
            constant strb : in std_logic_vector((C_AXI_DATA_WIDTH / 8) - 1 downto 0) := (others => '1')
        ) is
        begin
            -- Wait for a clock edge
            wait until rising_edge(S_AXI_ACLK);
            
            -- Phase 1: Address Write Channel
            S_AXI_AWADDR <= addr;
            S_AXI_AWVALID <= '1';
            S_AXI_AWPROT <= "000";  -- Normal, non-secure, data access
            
            -- Phase 2: Write Data Channel (can be concurrent with address)
            S_AXI_WDATA <= data;
            S_AXI_WSTRB <= strb;
            S_AXI_WVALID <= '1';
            
            -- Wait for address write handshake
            wait until rising_edge(S_AXI_ACLK) and S_AXI_AWREADY = '1';
            S_AXI_AWVALID <= '0';
            
            -- Wait for write data handshake
            wait until rising_edge(S_AXI_ACLK) and S_AXI_WREADY = '1';
            S_AXI_WVALID <= '0';
            
            -- Phase 3: Write Response Channel
            S_AXI_BREADY <= '1';
            
            -- Wait for write response
            wait until rising_edge(S_AXI_ACLK) and S_AXI_BVALID = '1';
            
            -- Check response (optional)
            if S_AXI_BRESP /= "00" then  -- "00" = OKAY
                report "AXI Write Error: BRESP = " & integer'image(to_integer(unsigned(S_AXI_BRESP))) severity warning;
            end if;
            
            S_AXI_BREADY <= '0';
            
            -- Clean up signals
            S_AXI_AWADDR <= (others => '0');
            S_AXI_WDATA <= (others => '0');
            S_AXI_WSTRB <= (others => '0');
            
            wait until rising_edge(S_AXI_ACLK);
        end procedure;
    begin
        -- Wait for reset deassertion
        wait until S_AXI_ARESETN = '1';
        wait for 100 ns;  -- Additional setup time
        
        -- Test multiple write transactions
        report "Starting AXI4-Lite Write Transactions" severity note;
        
        -- Write to WRITE_DATA_REGISTER (address 0x04)
        axi_write_transaction(x"4", x"DEADBEEF");
        wait for 50 ns;
        
        axi_write_transaction(x"4", x"CAFEBABE");
        wait for 50 ns;
        
        axi_write_transaction(x"4", x"12345678");
        wait for 50 ns;
        
        axi_write_transaction(x"4", x"ABCD1234");
        wait for 50 ns;
        
        report "Completed AXI4-Lite Write Transactions" severity note;
        wait;
    end process;

    -- AXI4-Lite Read Transaction Process
    axi_read_proc: process
        -- Procedure for AXI4-Lite Read Transaction
        procedure axi_read_transaction(
            constant addr : in std_logic_vector(C_AXI_ADDRESS_WIDTH - 1 downto 0);
            variable data : out std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0)
        ) is
        begin
            -- Wait for a clock edge
            wait until rising_edge(S_AXI_ACLK);
            
            -- Phase 1: Address Read Channel
            S_AXI_ARADDR <= addr;
            S_AXI_ARVALID <= '1';
            S_AXI_ARPROT <= "000";  -- Normal, non-secure, data access
            
            -- Wait for address read handshake
            wait until rising_edge(S_AXI_ACLK) and S_AXI_ARREADY = '1';
            S_AXI_ARVALID <= '0';
            
            -- Phase 2: Read Data Channel
            S_AXI_RREADY <= '1';
            
            -- Wait for read data
            wait until rising_edge(S_AXI_ACLK) and S_AXI_RVALID = '1';
            data := S_AXI_RDATA;
            
            -- Check response (optional)
            if S_AXI_RRESP /= "00" then  -- "00" = OKAY
                report "AXI Read Error: RRESP = " & integer'image(to_integer(unsigned(S_AXI_RRESP))) severity warning;
            end if;
            
            S_AXI_RREADY <= '0';
            
            -- Clean up signals
            S_AXI_ARADDR <= (others => '0');
            
            wait until rising_edge(S_AXI_ACLK);
        end procedure;
        
        variable read_data : std_logic_vector(C_AXI_DATA_WIDTH - 1 downto 0);
    begin
        -- Wait for reset and some writes to complete
        wait until S_AXI_ARESETN = '1';
        wait for 500 ns;  -- Let writes complete first
        
        report "Starting AXI4-Lite Read Transactions" severity note;
        
        -- Read from READ_DATA_REGISTER (address 0x00) - FIFO output
        axi_read_transaction(x"0", read_data);
        report "Read from FIFO: 0x" & to_hex_string(read_data) severity note;
        wait for 50 ns;
        
        axi_read_transaction(x"0", read_data);
        report "Read from FIFO: 0x" & to_hex_string(read_data) severity note;
        wait for 50 ns;
        
        -- Read FIFO status (address 0x08)
        axi_read_transaction(x"8", read_data);
        report "FIFO Status: 0x" & to_hex_string(read_data) severity note;
        wait for 50 ns;
        
        report "Completed AXI4-Lite Read Transactions" severity note;
        wait;
    end process;

    -- Old stimulus (commented out)
    -- S_AXI_AWVALID <= '1' after 1.100 us,
    --                  '0' after 1.116 us;
    -- S_AXI_AWADDR <= "0100" after 1.100 us,
    --                 "0000" after 1.116 us;
    -- S_AXI_WSTRB <= "1111";
    -- S_AXI_WDATA <= X"BADBABE5" after 1.116 us,
    --                X"00000000" after 1.132 us;
    -- S_AXI_WVALID <= '1' after 1.116 us,
    --                 '0' after 1.132 us;
    -- S_AXI_BREADY <= '1' after 1.140 us,
    --                 '0' after 1.148 us;
    -- S_AXI_ARVALID <= '1' after 1.180 us,
    --                  '0' after 1.196 us,
    --                  '1' after 1.300 us,
    --                  '0' after 1.316 us;
    -- S_AXI_ARADDR <= "1000" after 1.180 us,
    --                 "0000" after 1.196 us,                
    --                 "0000" after 1.300 us,
    --                 "0000" after 1.316 us;
    -- S_AXI_RREADY <= '1' after 1.204 us,
    --                 '0' after 1.212 us,
    --                 '1' after 1.324 us,
    --                 '0' after 1.332 us;

    -- S_AXI_ARVALID <= '1' after 1.220 us,
    --                  '0' after 1.236 us,
    --                  '1' after 1.260 us,
    --                  '0' after 1.276 us;
    -- -- S_AXI_ARADDR <= "0000101100" after 1.204 us,
    -- --                 "0000000000" after 1.220 us;
    -- S_AXI_ARADDR <= "00000" after 1.220 us,
    --                 "00000" after 1.236 us,
    --                 "00000" after 1.260 us,
    --                 "00000" after 1.276 us;
    -- S_AXI_RREADY <= '1' after 1.244 us,
    --                 '0' after 1.252 us,
    --                 '1' after 1.284 us,
    --                 '0' after 1.292 us;

end behavioral;
