class Company {
  String? companyName;
  //String? companyWebsite;
  String? companyEmail;
  //String? companyAddress;
  String? companyTel1;
  String? companyTel2;

  Company(
      {this.companyName,
      //this.companyWebsite,
      this.companyEmail,
      //this.companyAddress,
      this.companyTel1,
      this.companyTel2});

  Company.fromJson(Map<String, dynamic> json) {
    companyName = json['company_name'];
    //companyWebsite = json['company_website'];
    companyEmail = json['company_email'];
    //companyAddress = json['company_address'];
    companyTel1 = json['company_tel1'];
    companyTel2 = json['company_tel2'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['company_name'] = companyName;
    //data['company_website'] = companyWebsite;
    data['company_email'] = companyEmail;
    //data['company_address'] = companyAddress;
    data['company_tel1'] = companyTel1;
    data['company_tel2'] = companyTel2;
    return data;
  }
}
