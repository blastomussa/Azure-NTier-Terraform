import random
from english_dictionary.scripts.read_pickle import get_dict

class Generator():
    def __init__ (self):
        self.SPECS_LIST = ["!","@","#","$","%","^","&","*","_","+","-","=","?","<",">","|"]
        self.WORDS = []
        self.LENGTHS = {}
        # Build GLOBAL length dictionary and word list
        words_dict = get_dict()
        for word in words_dict:
            if word.islower(): #only match lower case words
                self.WORDS.append(word)
                self.LENGTHS.update({word:len(word)})

    #Concat random words and make sure final string is in MIN/MAX range
    def get_words(self,max, min, num_words, num_ints, num_specs):
        i = 0
        string = ''
        total_length = num_ints + num_specs
        iterations = 0
        while i < num_words:
            i = i + 1
            word = random.choice(self.WORDS)
            string = string + word
            total_length = total_length + self.LENGTHS[word]
            # reset and try again if string is too long
            if total_length > max or total_length < min:
                iterations = iterations + 1
                string = ''
                i = 0
                total_length = num_ints + num_specs
                if iterations == 10000: # prevent endless looping; tries 10000 word combos
                    string = "No password could be generated with the given parameters"
                    break
        return string

    # add capital letters to password string
    def add_caps(self, string, num_caps, loc_caps):
        i = 0
        start = 0
        end = -1
        while i < num_caps:
            i = i + 1
            if loc_caps.lower() == 'first':
                string = string.replace(string[start],string[start].upper(),1)
            elif loc_caps.lower() == 'last':
                # sometimes matches earleir character than the last, hmmm whats the solution
                string = string.replace(string[end],string[end].upper(),1)
            elif loc_caps.lower() == 'random':
                length = len(string)
                index = random.randrange(length)
                string = string.replace(string[index],string[index].upper(),1)
            else: pass
            start = start + 1
            end = end - 1
        return string

    # add integers to password string
    def add_ints(self, string, num_ints, loc_ints):
        # build approriate range
        i = 0
        range = 1
        while i < num_ints:
            i = i + 1
            range = range * 10
        integer = random.randrange((range/10),range)
        if loc_ints.lower() == 'first':
            string = str(integer) + string
        elif loc_ints.lower() == 'last':
            string = string + str(integer)
        elif loc_ints.lower() == 'random':
            for int in str(integer):
                length = len(string)
                index = random.randrange(length)
                string = string[:index] + int + string[index:]
        else: pass
        return string

    # add special characters from specified list
    def add_specs(self, string, num_specs, loc_specs):
        i = 0
        while i < num_specs:
            i = i + 1
            char = random.choice(self.SPECS_LIST)
            if loc_specs.lower() == 'first': string = char + string
            elif loc_specs.lower() == 'last': string = string + char
            elif loc_specs.lower() == 'random':
                length = len(string)
                index = random.randrange(length)
                string = string[:index] + char + string[index:]
            else: pass
        return string

    # scramble string randomly to create gibberish
    def gibberish(self, string):
        l = len(string)
        for c in string: #switch characters in string randomly
            index = random.randrange(l)
            r = string[index]
            string = string.replace(c,r,1)
            string = string.replace(r,c,1)
        return string
