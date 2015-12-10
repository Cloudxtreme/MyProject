class StatusCodes:

    status_codes = {}
    status_codes["200"] = "HTTP OK"
    status_codes["201"] = "HTTP Created"
    status_codes["204"] = "HTTP No Content"
    status_codes["400"] = "HTTP Bad Request Error"
    status_codes["404"] = "HTTP Not Found Error"
    status_codes["405"] = "HTTP Method Not Allowed Error"
    status_codes["415"] = "HTTP Unsupported Media Type Error"
    status_codes["500"] = "HTTP Internal Server Error"
    status_codes["501"] = "HTTP Not Implemented Error"

    @classmethod
    def get_status(self, status_code):
        if status_code in self.status_codes:
            return self.status_codes[status_code]
        else:
            return "Status code does not exist"
