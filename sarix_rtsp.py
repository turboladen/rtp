#!/usr/bin/python

import sys
import socket
import traceback
import time
from threading import Thread

import threading
import SocketServer
import struct
import re

import subprocess
import os.path


class RepeatTimer(threading.Thread):
    def __init__(self, interval, function, iterations=0, args=[], kwargs={}):
        threading.Thread.__init__(self)
        self.interval = interval
        self.function = function
        self.iterations = iterations
        self.args = args
        self.kwargs = kwargs
        self.finished = threading.Event()
 
    def run(self):
        count = 0
        while not self.finished.is_set() and (self.iterations <= 0 or count <
self.iterations):
            self.finished.wait(self.interval)
            if not self.finished.is_set():
                self.function(*self.args, **self.kwargs)
                count += 1
 
    def cancel(self):
        self.finished.set()

class FFMPEGHelper:
    def __init__(self, video_filename_full):
        self.video_filename_full = video_filename_full
        self.video_path = os.path.dirname(video_filename_full)
        self.video_filename = os.path.basename(video_filename_full)

    def process(self, result_filename="media", transcoder_options=None, delete_old_file=False):
        self.result_filename = result_filename

        cmd = "ffmpeg -i \"%s\"" % self.video_filename_full
        # Add any ffmpeg_options passed
        if transcoder_options:
            for key, value in transcoder_options.items():
                if value:
                    cmd += " %s %s" % (key, value)
                else:
                    cmd += " %s" % (key)

        cmd +=" \"%s\"" % self.result_filename
        print "CMD: %s" % cmd
        p = subprocess.Popen(cmd, cwd=self.video_path, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        p.wait()
        if p.returncode > 0:
            error_message = 'Error creating file: file=%s ffmpeg-stdout=%s ffmpeg command=%s' % (self.result_filename, p.communicate()[0], cmd)
            raise Exception(error_message)
        if delete_old_file == True:
            print "Deleting %s" % self.video_filename
            cmd = "rm -f " + self.video_filename
            p = subprocess.Popen(cmd, cwd=self.video_path, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            p.wait()
            if p.returncode > 0:
                error_message = 'File deleteion failed for file=%s' % (self.result_filename)
                raise Exception(error_message)



class RequestHandler(SocketServer.BaseRequestHandler):

    def __init__(self, request, client_address, server):

        self.video_file = server.video_file
        self.server = server
        SocketServer.BaseRequestHandler.__init__(self, request, client_address,server)

    def handle(self):
        data = (self.request[0])
        # Get RTP Header Info...
        # Note: Marker flag is payload_type & 128
        #       actual payload type is payload_type & 127
        flags, payload_type, sequence_number, timestamp, ssid = struct.unpack('!BBHII', data[0:12])
        if self.server.previous_timestamp != 0 and self.server.previous_timestamp != timestamp:
            #print "This is the first packet of a new frame!!"
            curr_time = time.time()
            #if (curr_time - self.server.time) >= self.server.clip_length:
            if (curr_time - self.server.time) >= 10:
                #print "Closing file on end of frame"
                self.server.time = curr_time
                # Close the file and convert to a .ts
                self.server.process_file()
                # Get a new filename / handle
                self.server.get_new_file_handle()
                self.video_file = self.server.video_file

        self.server.previous_timestamp = timestamp

        video_data = data[12:]
        nal_header = struct.unpack('!B', video_data[0])[0]
        nal_unit_type = (nal_header & 0x1f)
        try:
            # nal_type_FU_A and nal_type_FU_B
            if nal_unit_type == 28 or nal_unit_type == 29:
                fu_header = struct.unpack('!B', video_data[1])[0]
                S = bool(fu_header & 0x80)
                if S:
                    recalc_nal_header = (nal_header & 0xe0) | (fu_header & 0x1f)
                    recalc_nal_string = struct.pack('!B', recalc_nal_header)
                    self.video_file.write('\x00\x00\x00\x01' + recalc_nal_string + video_data[2:])
                else:
                    self.video_file.write(video_data[2:])

            elif (nal_unit_type >= 1) and (nal_unit_type <= 23):
                self.video_file.write('\x00\x00\x00\x01' + video_data)
            else:
                print "ERROR: UNHANDLED H264 FRAME TYPE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        except:
            traceback.print_exc()
            time.sleep(5)

class ThreadedUDPServer(SocketServer.UDPServer):

    def __init__(self, server_address, handler_class):
        self.time = time.time()
        self.file_name = str(self.time).split(".")[0]
        self.video_file = open(self.file_name + ".raw", 'wb+')
        self.m3u8_file_name = "test.m3u8"
        self.file_counter = 0
        self.last_seq_num = 0
        # Length of each clip in the file
        self.clip_length = 3
        self.clips_per_m3u = 3
        self.frame_event = threading.Event()
        self.previous_timestamp = 0
        self.cleanup_timer = RepeatTimer(10, self.cleanup_old_files)
        self.cleanup_timer.start()
        SocketServer.UDPServer.__init__(self, server_address, handler_class)

    def cleanup_old_files(self):
        print "Calling cleanup!"
        files=os.listdir(".")
        files.sort()
        curr_time = str(time.time())
        curr_time = curr_time.split(".")[0]
        for file in files:
            if ".ts" in file:
                file_str = file
                file_str = re.sub('.ts', '', file_str)
                file_str = re.sub('-.*', '', file_str)
                file_num = int(file_str)
                print  "if %s <  %s --- DELETE FILE!" %(file_num, int(curr_time)-60)
                if file_num < (int(curr_time) - 60):
                    print "Going to delete %s" % file
                    os.remove(file)
            #if ".raw" in file:
            #    file_num = int(file.split(".")[0])
            #    #print  "Found File %s %s" %(file, file_num)
            #    if file_num < (int(curr_time) - 30):
            #        print "Going to delete %s" % file
            #        os.remove(file)

    def update_m3u(self, base_file_name, count):
            last_seq_num = self.last_seq_num
            base_url="http://10.221.221.239:8000/video_streaming/streamingvideo/"
            headers="#EXTM3U\n#EXT-X-TARGETDURATION:5\n#EXT-X-MEDIA-SEQUENCE:"+ str(last_seq_num) + "\n"
            #EXT-X-VERSION
            #EXT-X-ALLOW-CACHE:NO\n"
            base_count = int(base_file_name)
            for i in range(count):
                headers +="#EXTINF:%s,\n" % self.clip_length
                headers += base_url + str(base_count) + "_" + str(last_seq_num) + ".ts" + "\n"
                base_count += self.clip_length
                last_seq_num += 1
            #headers += "#EXT-X-ENDLIST\n"
            #print headers
            file = open(self.m3u8_file_name, 'wb+')
            file.seek(0)
            file.write(headers)
            file.close()

    def get_new_file_handle(self):
        new_filename = str((int(self.file_name) + self.clip_length))
        self.file_name = new_filename
        self.video_file = open(self.file_name + ".raw", 'wb+')
        self.last_seq_num += 1

    def process_file(self):
        self.video_file.close()
        ffmpeg = FFMPEGHelper("./" + self.file_name + ".raw")

        trans_options={}
        trans_options['-vcodec'] = "copy"
        #trans_options['-vcodec'] = "libx264"
        #trans_options['-f'] = "mpegts"
        #trans_options['-r'] = "15"
        #trans_options['-s'] = "480x272"
        #trans_options['-b'] = "400k"
        #trans_options['-flags'] = "+loop"
        #trans_options['-cmp'] = "+chroma"
        #trans_options['-partitions'] = "+parti4x4+partp8x8+partb8x8"
        #trans_options['-subq'] = "5"
        #trans_options['-trellis'] = "1"
        #trans_options['-refs'] = "1"
        #trans_options['-coder'] = "0"
        #trans_options['-me_range'] = "16"
        #trans_options['-keyint_min'] = "25"
        #trans_options['-sc_threshold'] = "40"
        #trans_options['-i_qfactor'] = "0.71"
        #trans_options['-bt'] = "200k"
        #trans_options['-maxrate'] = "400k"
        #trans_options['-bufsize'] = "400k"
        #trans_options['-rc_eq'] = "'blurCplx^(1-qComp)'"
        #trans_options['-qcomp'] = "0.6"
        #trans_options['-qmin'] = "10"
        #trans_options['-qmax'] = "51"
        #trans_options['-qdiff'] = "4"
        #trans_options['-level'] = "30"
        #trans_options['-aspect'] = "480:272"
        #trans_options['-g'] = "30"
        #trans_options['-async'] = "2"
        #ts_filename = self.file_name + "-" + str(self.last_seq_num) + ".ts" 
        ts_filename = self.file_name + ".ts" 
        ffmpeg.process(result_filename=ts_filename, transcoder_options=trans_options, delete_old_file=True)
        time_str = str(time.time()).split(".")[0]
        cmd = "./segmenter %s %s %s %s %s" % (ts_filename, self.clip_length, time_str, self.m3u8_file_name + ".seg", "http://10.221.221.239:8000/video_streaming/streamingvideo/")
        print "CMD: %s" % cmd
        p = subprocess.Popen(cmd, cwd=".", shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        p.wait()
        if p.returncode > 0:
            error_message = 'Error creating file: file=%s stdout=%s command=%s' % (ts_filename, p.communicate()[0], cmd)
            raise Exception(error_message)

        #print "Opening File %s" % self.m3u8_file_name
        temp = open(self.m3u8_file_name + ".seg", 'r')
        lines = temp.readlines()
        m3ufile = open(self.m3u8_file_name, 'wb+')
        for line in lines:
            #print line
            if "EXTM3U" in line:
                m3ufile.write(line)
                m3ufile.write("#EXT-X-MEDIA-SEQUENCE:1")
            if not "ENDLIST" in line: 
                m3ufile.write(line)
        temp.close()
        m3ufile.close()
        #self.cleanup_old_files()
        #if self.file_counter == 0:
        #    self.update_m3u(self.file_name, self.clips_per_m3u)
        #    self.file_counter = self.clips_per_m3u
        #    self.cleanup_old_files()
        #self.file_counter -= 1


    def finish_request(self, request, client_address):
        """Finish one request by instantiating RequestHandlerClass."""
        self.RequestHandlerClass(request, client_address, self)


class RtspClient(Thread):
    MAX_KEEP_ALIVE_FAILURE_COUNT = 3

    def __init__(self, stream_source_ip, stream_source_port, stream_urn, stream_receive_ip, stream_receive_port):
        Thread.__init__(self)
        self.stream_source_ip = stream_source_ip
        self.stream_source_port = stream_source_port
        self.stream_source_path = stream_urn
        self.stream_receive_ip = stream_receive_ip
        self.stream_receive_port = stream_receive_port
        self.accept = ''
        self.transport = ''
        self.range = ''
        self.rtpinfo = ''
        self.postdata = ''
        self.session = ''
        self.seq = 0
        self.control = ""
        self.track = "/track1"
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.settimeout(10)
        self.socket.connect((self.stream_source_ip, self.stream_source_port,))

        self.server = ThreadedUDPServer((self.stream_receive_ip, self.stream_receive_port), RequestHandler)
        self.server_thread = threading.Thread(target=self.server.serve_forever)
        self.server_thread.setDaemon(True)

        self.sps = None
        self.pps = None

    def run(self):
        # Keep stream alive. If failure try again or restart stream
        rtsp_keep_alive_failure_count = 0
        self.server_thread.start()
        while True:
            try:
                # Handle failures and after so many attempt PLAY sequence again
                self.keep_alive()
                rtsp_keep_alive_failure_count = 0
                time.sleep(300)
            except:
                try:
                    if rtsp_keep_alive_failure_count >= self.MAX_KEEP_ALIVE_FAILURE_COUNT:
                        print " * RtspClient - Max number of keep alive failure attempts exceeded. Attempting to restart stream %s%s." % \
                            (self.stream_source_ip, self.stream_source_path)
                        try:
                            try:
                                # First attempt to tear down, Ignore a failure
                                self.teardown()
                            except:
                                pass
                            try:
                                # The teardown may or may not have got to the point of successfully closing the socket
                                # Try again to be sure
                                self.socket.close()
                            except:
                                pass

                            # Recreate the socket. Want to make sure that we're starting fresh and
                            # Will not have any stale data coming in through an old socket
                            # Also handles the case that an error occured with the previous socket instance
                            print " * RtspClient - Attempting to reinstanciate socket and request stream for %s%s" % \
                                (self.stream_source_ip, self.stream_source_path)
                            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                            self.socket.connect((self.stream_source_ip, self.stream_source_port,))

                            self.describe()
                            self.setup()
                            self.play()
                            print " * RtspClient - Successfully reinstantiated stream from %s%s." % \
                                (self.stream_source_ip, self.stream_source_path)
                            rtsp_keep_alive_failure_count = 0
                            continue
                        except:
                            print " ! RtspClient - Failed to reinitiate streaming from %s%s. Will try again..." % \
                                (self.stream_source_ip, self.stream_source_path)
                            time.sleep(5)
                    
                    rtsp_keep_alive_failure_count += 1
                    print " ! RtspClient - Failed to send keep alive for stream. Failure # %i" % \
                        (rtsp_keep_alive_failure_count)
                    time.sleep(5)
                except:
                    print " ! RtspClient - Unexpceted exception occured"
                    traceback.print_exc()

    def keep_alive(self):
        params = []
        params.append("GET_PARAMETER rtsp://%s%s RTSP/1.0" % (self.stream_source_ip, self.stream_source_path))
        self.seq += 1
        params.append("CSeq: %s" % self.seq)
        params.append("Session: %s" % self.session)
        arr_header, arr_body = self.send_request(params)

    def close(self):
        self.socket.close()
        
    def option(self):
        params = []
        self.seq += 1
        params.append("CSeq: %s" % self.seq)
        params.append("OPTIONS rtsp://%s%s RTSP/1.0" % (self.stream_source_ip, self.stream_source_path))
        header, body = self.send_request(params)

    def describe(self):
        params = []
        params.append("DESCRIBE rtsp://%s%s RTSP/1.0" % (self.stream_source_ip, self.stream_source_path))
        self.seq += 1
        params.append("CSeq: %s" % self.seq)
        params.append("Accept: application/sdp")
        header, body = self.send_request(params)
        for line in body:
            if "sprop-parameter-sets" in line.lower():
                print "==============================="
                self.sps = re.sub('.*sprop-parameter-sets=', '', line).split(",")[0]
                self.pps = re.sub('.*sprop-parameter-sets=', '', line).split(",")[1]

            if line.lower().find("a=control:") != -1:
                # control should contain the track. Save it if found
                control = line.split(":")[1]
                if control != "*":
                    self.track = '/' + control
        return(self.sps, self.pps) 

    def setup(self):
        self.session = None
        params = []
        params.append("SETUP rtsp://%s%s%s RTSP/1.0" % (self.stream_source_ip, self.stream_source_path, self.track))
        self.seq += 1
        params.append("CSeq: %s" % self.seq)
        params.append("Transport: RTP/AVP;unicast;destination=%s;client_port=%s-%s" % \
            (self.stream_receive_ip, self.stream_receive_port, self.stream_receive_port+1))
        header, body = self.send_request(params)
        for line in header:
            if line.lower().find("session") != -1:
                self.session = line.split(": ")[1]
        return self.session
        
    def play(self):
        params = []
        params.append("PLAY rtsp://%s%s/ RTSP/1.0" % (self.stream_source_ip, self.stream_source_path))
        self.seq += 1
        params.append("CSeq: %s" % self.seq)
        # @todo: unsure about this.. figure out if needed
        params.append("Range: ntp=0.000-")
        params.append("Session: %s" % self.session)
        header, body = self.send_request(params)
        
    def teardown(self):
        params = []
        params.append("TEARDOWN rtsp://%s%s/ RTSP/1.0" % (self.stream_source_ip, self.stream_source_path))
        self.seq += 1
        params.append("CSeq: %s" % self.seq)
        params.append("Session: %s" % self.session)
        header, body = self.send_request(params)
        self.socket.close()

    def send_request(self, params):
        request = self.build_request(params)
        print "\n\n\n\nREQUEST: %s" % request
        bytes_sent = self.socket.send(request)
        while bytes_sent < len(request):
            bytes_sent = bytes_sent + self.socket.send(request[bytes_sent:])

        data = self.socket.recv(1024)
        print "REC DATA:\n%s" % repr(data)
        header = []
        body = []
        data = data.split("\r\n\r\n")
        header = data[0].split("\r\n")
        body = data[1].split("\r\n")
        return(header, body,)

    def build_request(self, params):
        request = '\r\n'.join(params)
        request += "\r\n\r\n"
        return request
        

event = threading.Event()

#file_name = "./video.out"
#video_file = open(file_name, 'wb+')

#a=RtspClient("10.221.221.221", 554, "/stream2", "10.221.221.239", 10010)
a=RtspClient("192.168.1.104", 554, "/stream1", "192.168.1.105", 10010)
a.describe()
a.setup()
a.play()
a.start()
while True:
    event.wait() 
