class FilterModule(object):
    def filters(self):
        return {
            'map_to_key_value': self.map_to_key_value,
        }

    def map_to_key_value(self, data):
        result = ""
        for k in data:
            result += (',' if result else '') + k + '=' + data[k]

        return result
