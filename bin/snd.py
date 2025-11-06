#!/usr/bin/env python3

import sys
import subprocess
# You need this first
# https://github.com/deweller/switchaudio-osx
# brew install switchaudio-osx

def switch_audio(audioSource):
    # it'd be cool if I just toggled

    sas = "/opt/homebrew/bin/SwitchAudioSource"
    print(f"you are switching to {audioSource}")
    if audioSource == "h":
        completedProcess = subprocess.run([sas, '-s', 'Jabra EVOLVE 20'])
        #print(f"{completedProcess}")
        if (completedProcess != 0):
            subprocess.run([sas, '-s', 'Yeti Stereo Microphone'])
    elif audioSource == "s":
        completedProcess = subprocess.run([sas, '-s', 'Realtek USB2.0 Audio'])
        if (completedProcess != 0):
            subprocess.run([sas, '-s', 'AB13X USB Audio'])
    else:
        print(f"couldn't find a matching audio source for {audioSource}")
        #print("This is what SwitchAudioSource sees")
        #subprocess.run([sas, '-a'])

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("You need to tell me where to send the audio")
    audioSource = sys.argv[1]
    switch_audio(audioSource)

