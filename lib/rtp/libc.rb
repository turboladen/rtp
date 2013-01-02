require 'ffi'

module RTP
  module LibC
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    attach_function :fopen, [:pointer, :pointer], :pointer
    attach_function :fwrite, [:pointer, :uint, :uint, :pointer], :uint
    attach_function :fclose, [:pointer], :int
  end
end