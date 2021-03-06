//PE extension:  .cpl, .exe, .dll, .ocx, .sys, .scr, .drv, .efi, .pif

import "math"
import "pe"

rule Suspicious_Numbers_Section_API_PE
{
    meta:
        author = "Lionel PRAT"
        description = "Match suspicious number of section"
        reference = "https://github.com/secrary/SSMA/blob/master/src/check_file.py"
        version = "0.1"
		weight = 6
    condition:
		(uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL/) and 
		(pe.number_of_sections < 2 or pe.number_of_sections > 8)
}

rule Suspicious_checksum_PE
{
    meta:
        author = "Lionel PRAT"
        description = "Match suspicious checksum PE"
        reference = "https://github.com/secrary/SSMA/blob/master/src/check_file.py"
        version = "0.1"
		weight = 5
    condition:
		(uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL/) and 
		(pe.checksum == pe.calculate_checksum())
}

rule Suspicious_export_PE
{
    meta:
        author = "Lionel PRAT"
        description = "PE export function(s)"
        reference = "https://github.com/secrary/SSMA/blob/master/src/check_file.py"
        version = "0.1"
		weight = 4
    condition:
		(uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL/) and 
		(pe.number_of_exports > 0)
}

rule Suspicious_Section_Name_winPE
{
    meta:
        author = "Lionel PRAT"
        description = "Match suspicious name in section PE"
        reference = "https://github.com/secrary/SSMA/blob/master/src/check_file.py"
        version = "0.1"
		weight = 5
    condition:
		(uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL/) and 
		for any j in (0..pe.number_of_sections - 1): (not pe.sections[j].name matches /\.data|\.text|\.code|\.reloc|\.idata|\.edata|\.rdata|\.bss|\.rsrc/)
}

rule Suspicious_Section_size_winPE
{
    meta:
        author = "Lionel PRAT"
        description = "Suspicious rawdata length 0 and virtual size > 0 in section PE"
        reference = "https://github.com/secrary/SSMA/blob/master/src/check_file.py"
        version = "0.1"
		weight = 5
    condition:
		(uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL/) and 
		for any j in (0..pe.number_of_sections - 1): (pe.sections[j].raw_data_size == 0 and pe.sections[j].virtual_size > 0)
}

rule Suspicious_date_compilation_winPE
{
    meta:
        author = "Lionel PRAT"
        description = "Suspicious date compilation 7 day before now"
        version = "0.1"
		weight = 4
    condition:
		(uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL/) and 
		(pe.timestamp > now_7_int)
}

rule  Suspicious_dateRes_compilation_winPE
{
    meta:
        reference = "http://malbabble.blogspot.com/2015/08/pe-time-stamps-and-yara.html"
        description = "Suspicious date compilation"
		weight = 4
	condition:
		pe.resource_timestamp != 0 and
		pe.resource_timestamp < pe.timestamp
}
			
rule Entropy_Packed_Win_PE
{
	meta: 
		description = "Very high or very low entropy means that file is compressed or encrypted since truly random data is not common"
		weight = 6
		tag = "attack.defense_evasion"
	condition:
		// MZ signature at offset 0 and ...
		uint16(0) == 0x5A4D and
		// ... PE signature at offset stored in MZ header at 0x3C
		uint32(uint32(0x3C)) == 0x00004550 and
		(math.entropy(0, filesize) >= 7.0 or math.entropy(0, filesize) <= 1)
}

rule Entropy_Section_Win_PE
{
	meta: 
	    reference = "https://github.com/DFIRnotes/rules/blob/master/pe_upx.yara"
		description = "Very high or very low entropy means that section is compressed or encrypted since truly random data is not common"
		weight = 5
		tag = "attack.defense_evasion"
	condition:
		// MZ signature at offset 0 and ...
		uint16(0) == 0x5A4D and
		for any j in (0..pe.number_of_sections - 1): (
			math.entropy(pe.sections[j].raw_data_offset, pe.sections[j].raw_data_size) >= 6
		)
}

rule Notcontains_InternalOrOriginal_Name_winPE
{
    meta:
        author = "Lionel PRAT"
        description = "Pe not contains internalname or originalfilename" // NOT WORK! if version_info not exist, the pe.version_info don't put boolean response
        version = "0.1"
		weight = 4
    condition:
		(uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL/) and 
		((not pe.version_info["InternalName"] matches /\S+/) or (not pe.version_info["OriginalFilename"] matches /\S+/))
}
rule Win_PE_winnet
{
    meta:
        author = "Lionel PRAT"
        description = "Pe file call WINNET.dll" 
        version = "0.1"
		weight = 4
    condition:
		(uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL/) and pe.imports ("wininet.dll") 
}

rule dotnet
{
    meta:
        description = "Potential Dotnet code - you can decompile with ilspy"
        author = "Lionel PRAT"
        version = "0.1"
        weight = 1
        reference = "book .NET IL Assembler page 68"
    strings:
        $dotnetMagic = "BSJB" ascii
    condition:
        (uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL|CL_TYPE_binary/) and $dotnetMagic
}

rule exe_pyinst
{
    meta:
        description = "Potential Python executable (use pyinstxtractor or binwalk)"
        author = "Lionel PRAT"
        version = "0.1"
        weight = 1
        reference = "https://sourceforge.net/projects/pyinstallerextractor/"
    strings:
        $pythonMagic = "MEI\x0c\x0b\x0a\x0b\x0e" ascii
    condition:
        (uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL|CL_TYPE_binary/) and $pythonMagic
}

rule py2exe
{
    meta:
        description = "Potential Python executable (use unpy2exe)"
        author = "Lionel PRAT"
        version = "0.1"
        weight = 1
        reference = "https://github.com/matiasb/unpy2exe/blob/master/unpy2exe.py"
    strings:
        $pyinstaller = "MEI\x0c\x0b\x0a\x0b\x0e" ascii
        $pythonMagix = "\x03\xf3\x0d\x0a" ascii
        $pythonMagic1 = "\x99N\x0d\x0a" ascii
        $pythonMagic2 = "\xfc\xc4\x0d\x0a" ascii
        $pythonMagic3 = "\x87\xc6\x0d\x0a" ascii
        $pythonMagic4 = "*\xeb\x0d\x0a" ascii
        $pythonMagic5 = "-\xed\x0d\x0a" ascii
        $pythonMagic6 = ";\xf2\x0d\x0a" ascii
        $pythonMagic7 = "m\xf2\x0d\x0a" ascii
        $pythonMagic8 = "\xb3\xf2\x0d\x0a" ascii
        $pythonMagic9 = "\xd1\xf2\x0d\x0a" ascii
        $pythonMagic10 = "\xef\xf2\x0d\x0a" ascii
        $pythonMagic11 = "\xb8\x0b\x0d\x0a" ascii
        $pythonMagic12 = "E\x0c\x0d\x0a" ascii
        $pythonMagic13 = "X\x0c\x0d\x0a" ascii
        $pythonMagic14 = "v\x0c\x0d\x0a" ascii
        $pythonMagic15 = "\xb2\x0c\x0d\x0a" ascii
        $pythonMagic16 = "\x16\x0d\x0d\x0a" ascii
        $pythonMagic17 = " \x0d\x0d\x0a" ascii
        $pythonMagic18 = ">\x0d\x0d\x0a" ascii
    condition:
        (uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL|CL_TYPE_binary/) and (any of ($pythonMagic*) or ($pythonMagix and not $pyinstaller))
}

rule autoit
{
    meta:
        description = "Potential autoit executable"
        author = "Lionel PRAT"
        version = "0.1"
        weight = 4
        reference = "https://github.com/Cisco-Talos/clamav-devel/blob/c68f996e6a6f252be5210634f4429a6f1bd8e3f5/libclamav/filetypes_int.h"
    strings:
        $autoit = "\xa3\x48\x4b\xbe\x98\x6c\x4a\xa9\x99\x4c\x53\x0a\x86\xd6\x48\x7d\x41\x55\x33\x21\x45\x41\x30" ascii
    condition:
        (uint16(0) == 0x5A4D or FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL|CL_TYPE_binary/) and $autoit
}        

rule Win_PE
{
    meta:
        author = "Lionel PRAT"
        description = "Pe file" 
        version = "0.1"
		weight = 1
		check_level2 = "check_winapi_bool,check_registry_bool,check_command_bool,check_clsid_bool"
	strings:
		$magic_class = { ca fe ba be }
    condition:
		uint16(0) == 0x5A4D or (FileType matches /CL_TYPE_AUTOIT|CL_TYPE_MSCAB|CL_TYPE_MSEXE|CL_TYPE_MS-EXE|CL_TYPE_MS-DLL|CL_TYPE_binary/ and not (CDBNAME matches /.*\.class$/i or $magic_class at 0))
}

