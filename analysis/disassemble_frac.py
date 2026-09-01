from __future__ import annotations

import argparse
import re
import struct
from collections import deque
from pathlib import Path

from capstone import CS_ARCH_X86, CS_MODE_16, Cs


TERMINATORS = {"hlt", "iret", "ret", "retf"}
CONDITIONAL_JUMPS = {
    "ja", "jae", "jb", "jbe", "je", "jg", "jge", "jl", "jle", "jne", "jno", "jnp", "jns", "jo",
    "jp", "js", "jcxz", "loop", "loope", "loopne",
}


def word(data: bytes, offset: int) -> int:
    return struct.unpack_from("<H", data, offset)[0]


def immediate(text: str) -> int | None:
    match = re.fullmatch(r"(?:word ptr )?(0x[0-9a-f]+|[0-9]+)", text)
    return int(match.group(1), 0) if match else None


def local_far_target(text: str) -> int | None:
    match = re.fullmatch(r"0(?:x0)?, (0x[0-9a-f]+|[0-9]+)", text)
    return int(match.group(1), 0) if match else None


def discover(image: bytes, entry: int) -> dict[int, object]:
    decoder = Cs(CS_ARCH_X86, CS_MODE_16)
    pending = deque([entry])
    instructions: dict[int, object] = {}

    while pending:
        address = pending.popleft()
        while 0 <= address < len(image) and address not in instructions:
            decoded = next(decoder.disasm(image[address:address + 15], address, count=1), None)
            if decoded is None:
                break
            instructions[address] = decoded
            following = address + decoded.size
            mnemonic = decoded.mnemonic

            if mnemonic in TERMINATORS:
                break
            if mnemonic in {"call", "jmp"}:
                target = immediate(decoded.op_str)
                if target is not None:
                    pending.append(target)
                if mnemonic == "jmp":
                    break
            elif mnemonic in {"lcall", "ljmp"}:
                target = local_far_target(decoded.op_str)
                if target is not None:
                    pending.append(target)
                if mnemonic == "ljmp":
                    break
            elif mnemonic in CONDITIONAL_JUMPS:
                target = immediate(decoded.op_str)
                if target is not None:
                    pending.append(target)
            address = following

    return instructions


def write_listing(path: Path, source: Path, data: bytes, entry: int, instructions: dict[int, object]) -> None:
    header_size = word(data, 8) * 16
    with path.open("w", encoding="utf-8", newline="\n") as output:
        output.write(f"; Recursive 8086 disassembly of {source.name}\n")
        output.write(f"; MZ header: {header_size} bytes; load-module entry: 0000:{entry:04X}\n")
        output.write(f"; Discovered instructions: {len(instructions)}\n\n")
        for address in sorted(instructions):
            instruction = instructions[address]
            machine_code = instruction.bytes.hex(" ")
            output.write(
                f"{address:04X}:  {machine_code:<23} {instruction.mnemonic:<8} {instruction.op_str}\n"
            )


def main() -> None:
    parser = argparse.ArgumentParser(description="Recursively disassemble the 16-bit DOS FRAC executable.")
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    arguments = parser.parse_args()

    data = arguments.source.read_bytes()
    if data[:2] != b"MZ":
        raise ValueError("The input is not an MZ executable")
    header_size = word(data, 8) * 16
    entry = word(data, 22) * 16 + word(data, 20)
    instructions = discover(data[header_size:], entry)
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    write_listing(arguments.output, arguments.source, data, entry, instructions)
    print(f"Wrote {len(instructions)} instructions to {arguments.output}")


if __name__ == "__main__":
    main()
